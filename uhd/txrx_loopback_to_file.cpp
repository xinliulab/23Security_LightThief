//
// Copyright 2010-2012,2014-2015 Ettus Research LLC
// Copyright 2018 Ettus Research, a National Instruments Company
//
// SPDX-License-Identifier: GPL-3.0-or-later
//

#include "wavetable.hpp"
#include <uhd/exception.hpp>
#include <uhd/types/tune_request.hpp>
#include <uhd/usrp/multi_usrp.hpp>
#include <uhd/utils/safe_main.hpp>
#include <uhd/utils/static.hpp>
#include <uhd/utils/thread.hpp>
#include <boost/algorithm/string.hpp>
#include <boost/bind.hpp>
#include <boost/filesystem.hpp>
#include <boost/format.hpp>
#include <boost/math/special_functions/round.hpp>
#include <boost/program_options.hpp>
#include <boost/thread/thread.hpp>
#include <csignal>
#include <fstream>
#include <iostream>
#include <algorithm>
#include <chrono>
#include <complex>
// #include "usrp_gpio.hpp" this doesn't work

namespace po = boost::program_options;

/***********************************************************************
 * Signal handlers
 **********************************************************************/
static bool stop_signal_called = false;
// static bool tx_underflowed = false;
static bool tx_any_error = false;
static bool rx_any_error = false;


void sig_int_handler(int)
{
    stop_signal_called = true;
}

std::string to_bit_string(uint32_t val, const size_t num_bits)
{
    std::string out;
    for (int i = num_bits - 1; i >= 0; i--) {
        std::string bit = ((val >> i) & 1) ? "1" : "0";
        out += "  ";
        out += bit;
    }
    return out;
}

void output_reg_values(const std::string bank,
    const uhd::usrp::multi_usrp::sptr& usrp,
    const size_t num_bits)
{
    const std::vector<std::string> attrs = {
        "CTRL", "DDR", "ATR_0X", "ATR_RX", "ATR_TX", "ATR_XX", "OUT", "READBACK"};
    std::cout << (boost::format("%10s ") % "Bit");
    for (int i = num_bits - 1; i >= 0; i--)
        std::cout << (boost::format(" %2d") % i);
    std::cout << std::endl;
    for (const auto& attr : attrs) {
        const uint32_t gpio_bits = uint32_t(usrp->get_gpio_attr(bank, attr));
        std::cout << (boost::format("%10s:%s") % attr
                         % to_bit_string(gpio_bits, num_bits))
                  << std::endl;
    }
}

void usrp_gpio_arm_trigger(uhd::usrp::multi_usrp::sptr usrp)
{
    // General definitions
    #define GPIO_PANEL "FP0"
    #define ALL_BITS 0xfff
    // ATR configuration
    // #define TRIGGER_BIT (0x001 << 0)
    #define TRIGGER_BIT (0xff)
    #define TX_BIT (0x001 << 0 | 0x001 << 1 | 0x001 << 2 | 0x001 << 3)
    // #define XX_BIT (0x001 << 4)
    // #define RX_BIT (0x001 << 4)
    #define ATR_MASK (TRIGGER_BIT)

    // Set bit to automatic control mode
    usrp->set_gpio_attr(GPIO_PANEL, "CTRL", TX_BIT, ATR_MASK);
    // Set trigger as output
    usrp->set_gpio_attr(GPIO_PANEL, "DDR", TX_BIT, ATR_MASK);
    // Set up trigger
    usrp->set_gpio_attr(GPIO_PANEL, "ATR_TX", 0, ATR_MASK);
    usrp->set_gpio_attr(GPIO_PANEL, "ATR_RX", 0, ATR_MASK);
    usrp->set_gpio_attr(GPIO_PANEL, "ATR_XX", TX_BIT, ATR_MASK);
    usrp->set_gpio_attr(GPIO_PANEL, "ATR_0X", 0, ATR_MASK);
}

/***********************************************************************
 * Utilities
 **********************************************************************/
//! Change to filename, e.g. from usrp_samples.dat to usrp_samples.00.dat,
//  but only if multiple names are to be generated.
std::string generate_out_filename(
    const std::string& base_fn, size_t n_names, size_t this_name)
{
    if (n_names == 1) {
        return base_fn;
    }

    boost::filesystem::path base_fn_fp(base_fn);
    base_fn_fp.replace_extension(boost::filesystem::path(
        str(boost::format("%02d%s") % this_name % base_fn_fp.extension().string())));
    return base_fn_fp.string();
}


/***********************************************************************
 * transmit_worker function
 * A function to be used as a boost::thread_group thread for transmitting
 **********************************************************************/
void transmit_worker(std::vector<std::complex<float>> buff,
    wave_table_class wave_table,
    uhd::tx_streamer::sptr tx_streamer,
    uhd::tx_metadata_t metadata,
    size_t step,
    size_t index,
    int num_channels)
{
    std::vector<std::complex<float>*> buffs(num_channels, &buff.front());

    // send data until the signal handler gets called
    while (not stop_signal_called) {
        // fill the buffer with the waveform
        for (size_t n = 0; n < buff.size(); n++) {
            buff[n] = wave_table(index += step);
        }

        // send the entire contents of the buffer
        tx_streamer->send(buffs, buff.size(), metadata);

        metadata.start_of_burst = false;
        metadata.has_time_spec  = false;
    }

    // send a mini EOB packet
    metadata.end_of_burst = true;
    tx_streamer->send("", 0, metadata);
}

// copied from tx_samples_from_file.cpp
void send_from_file(uhd::tx_streamer::sptr tx_stream, const std::string& file, double settling_time)
// void send_from_file(uhd::tx_streamer::sptr tx_stream, std::vector<std::complex<float>>& buff, double settling_time)
{
    // Give this thread realtime
    uhd::set_thread_priority_safe();

    size_t samps_per_buff = tx_stream->get_max_num_samps();
    uhd::tx_metadata_t md;
    md.start_of_burst = true;
    md.end_of_burst   = false;
    md.has_time_spec  = true;
    md.time_spec      = uhd::time_spec_t(settling_time);
    
    //// V1
    std::vector<std::complex<float>> buff(samps_per_buff, std::complex<float>(0.0, 0.0));
    std::ifstream infile(file.c_str(), std::ifstream::binary);
    // loop until the entire file has been read
    while (not md.end_of_burst and not stop_signal_called) {
        infile.read((char*)&buff.front(), buff.size() * sizeof(std::complex<float>));
        size_t num_tx_samps = size_t(infile.gcount() / sizeof(std::complex<float>));
        // std::cout << num_tx_samps << " " << samps_per_buff << std::endl;
        md.end_of_burst = infile.eof();
        tx_stream->send(&buff.front(), num_tx_samps, md);

        // size_t samps_to_send = std::min(total_num_samps - num_acc_samps, buff.size());
        // size_t num_tx_samps = tx_stream->send(&buff.front(), samps_to_send, md);
        // if (num_tx_samps<samps_to_send){
        //     std::cout << "tx error\n"; 
        // }
        // num_acc_samps += num_tx_samps;
 
        // do not use time spec for subsequent packets
        md.start_of_burst = false; 
        md.has_time_spec = false;
    }
    infile.close();

    //// V2
    // // loop until the entire file has been read
    // size_t start_idx = 1, end_idx, sample_size = buff.size();
    // while (not md.end_of_burst and not stop_signal_called) {
    //     // infile.read((char*)&buff.front(), buff.size() * sizeof(std::complex<float>));
    //     // size_t num_tx_samps = size_t(infile.gcount() / sizeof(std::complex<float>));
        
    //     end_idx = std::min(start_idx+samps_per_buff, sample_size+1);
    //     size_t num_tx_samps = (end_idx - start_idx);
    //     // std::cout << num_tx_samps << " " << samps_per_buff << std::endl;
    //     md.end_of_burst = end_idx==(sample_size+1);
    //     tx_stream->send(&buff[start_idx-1], num_tx_samps, md);
    //     start_idx = end_idx;
    //     // size_t samps_to_send = std::min(total_num_samps - num_acc_samps, buff.size());
    //     // size_t num_tx_samps = tx_stream->send(&buff.front(), samps_to_send, md);
    //     // if (num_tx_samps<samps_to_send){
    //     //     std::cout << "tx error\n"; 
    //     // }
    //     // num_acc_samps += num_tx_samps;
 
    //     // do not use time spec for subsequent packets
    //     md.start_of_burst = false; 
    //     md.has_time_spec = false;
    // }

    // send a mini EOB packet
    md.end_of_burst = true;
    tx_stream->send("", 0, md);

    // Check for async messages (underflow)
    uhd::async_metadata_t async_msg;
    while (tx_stream->recv_async_msg(async_msg)) {
        // std::cout << "async msg: " << async_msg.event_code << std::endl;
        if (async_msg.event_code != uhd::async_metadata_t::EVENT_CODE_BURST_ACK) {
            tx_any_error = true;
        }
        switch (async_msg.event_code) {
            case uhd::async_metadata_t::EVENT_CODE_SEQ_ERROR:
            case uhd::async_metadata_t::EVENT_CODE_TIME_ERROR:
                std::cout << "Sequence or time error" << std::endl;
                break;
            case uhd::async_metadata_t::EVENT_CODE_UNDERFLOW_IN_PACKET:
                std::cout << "Underflow in packet" << std::endl;
            case uhd::async_metadata_t::EVENT_CODE_UNDERFLOW:
                // underflows++;
                // tx_underflowed = true;
                // std::cout << "Underflow" << std::endl;
                break;
            case uhd::async_metadata_t::EVENT_CODE_BURST_ACK:
                break;
            default:
                break;
        }
    }
}

// /*******************************************************
//  * send_from_file
//  ******************************************************/
// void send_from_file(
//     uhd::tx_streamer::sptr tx_stream,
//     const std::string &file,
//     size_t samps_per_buff,
//     size_t num_channels,
//     uhd::tx_metadata_t md
// ){
//     // Give this thread realtime
//     uhd::set_thread_priority_safe();

//     // Buffers
//     std::vector<std::vector<std::complex<float>>> buffs(
//         num_channels, std::vector<std::complex<float>>(samps_per_buff));
//     std::vector<std::complex<float>*> buff_ptrs;
//     for (size_t i = 0; i < buffs.size(); i++) {
//         buff_ptrs.push_back(&buffs[i].front());
//     }
    
//     std::cout << "spb value: " << samps_per_buff << std::endl;
    
//     // Open files
//     std::vector<boost::shared_ptr<std::ifstream>> infiles;
//     for (size_t i = 0; i < buffs.size(); i++) {
//         const std::string this_filename = generate_out_filename(file, buffs.size(), i);
//         std::cout << "Opening tx data: " << this_filename<< std::endl;
//         infiles.push_back(boost::shared_ptr<std::ifstream>(
//             new std::ifstream(this_filename.c_str(), std::ofstream::binary)));
//         if(infiles[i]->fail()) {
//             std::cerr << "Failed to open file (" << strerror(errno) << "!  Will not transmit" << std::endl;
//         }
//     }
//     UHD_ASSERT_THROW(infiles.size() == buffs.size());

//     //loop until the entire file has been read
//     size_t underflows = 0;
//     auto start = std::chrono::system_clock::now();
//     while(not md.end_of_burst and not stop_signal_called){

//         // Fill all tx buffers
//         size_t num_tx_samps;
//         for(size_t ch = 0; ch < num_channels; ch++) {
//             infiles[ch]->read((char*) buff_ptrs[ch], samps_per_buff*sizeof(std::complex<float>));
//             num_tx_samps = size_t(infiles[ch]->gcount()/sizeof(std::complex<float>));

//             md.end_of_burst = infiles[ch]->eof();

//             if(infiles[ch]->fail() && !(infiles[ch]->eof())) { // Ignore any errors if we're at EOF anyways, I guess
//                 if (errno==EAGAIN) {
//                     // It is very puzzling that I would get this error, since the file shouldn't be opened in non-blocking mode (?)
//                     // It seems to occur at EOF, so we might never actually reach this point
//                     continue;
//                 }
//                 std::cout << "tx read failed: " << strerror(errno) << std::endl;
//                 md.end_of_burst = true;
//             }
//         }
//         // Send all tx buffers
//         tx_stream->send(buff_ptrs, num_tx_samps, md);

//         // Check for async messages (underflow)
//         uhd::async_metadata_t async_msg;
//         if(tx_stream->recv_async_msg(async_msg)) {
//             switch (async_msg.event_code) {
//                 case uhd::async_metadata_t::EVENT_CODE_SEQ_ERROR:
//                 case uhd::async_metadata_t::EVENT_CODE_TIME_ERROR:
//                     std::cout << "Sequence or time error" << std::endl;
//                     tx_any_error=true;
//                     break;
//                 case uhd::async_metadata_t::EVENT_CODE_UNDERFLOW_IN_PACKET:
//                     std::cout << "Underflow in packet" << std::endl;
//                     tx_any_error=true;
//                 case uhd::async_metadata_t::EVENT_CODE_UNDERFLOW:
//                     underflows++;
//                     tx_underflowed = true;
//                     tx_any_error=true;
//                     break;
//                 default:
//                     break;
//             }
//         }

//         md.start_of_burst = false; // Corrected from example file
//         md.has_time_spec  = false;
//     }
//     auto end = std::chrono::system_clock::now();
//     auto duration = (end-start);
//     std::cout << "Elapsed time for tx: " << ((double) duration.count())/1000000000 << std::endl;

//     if (underflows > 0) {
//         std::cout << "Warning: " << underflows << " underflows!" << std::endl;
//         tx_underflowed = true;
//     }

//     for(size_t ch = 0; ch < num_channels; ch++) {
//         infiles[ch]->close();
//     }
// }


/***********************************************************************
 * recv_to_file function
 **********************************************************************/
template <typename samp_type>
void recv_to_file(uhd::usrp::multi_usrp::sptr usrp,
    const std::string& cpu_format,
    const std::string& wire_format,
    const std::string& file,
    size_t samps_per_buff,
    int num_requested_samples,
    double settling_time,
    std::vector<size_t> rx_channel_nums)
{
    // Give this thread realtime
    uhd::set_thread_priority_safe();

    // std::cout << "Saving rx data to: " << file << std::endl;
    int num_total_samps = 0;
    // create a receive streamer
    uhd::stream_args_t stream_args(cpu_format, wire_format);
    stream_args.channels             = rx_channel_nums;
    uhd::rx_streamer::sptr rx_stream = usrp->get_rx_stream(stream_args);

    samps_per_buff = rx_stream->get_max_num_samps();
    // Prepare buffers for received samples and metadata
    uhd::rx_metadata_t md;
    std::vector<std::vector<samp_type>> buffs(
        rx_channel_nums.size(), std::vector<samp_type>(samps_per_buff));
    // create a vector of pointers to point to each of the channel buffers
    std::vector<samp_type*> buff_ptrs;
    for (size_t i = 0; i < buffs.size(); i++) {
        buff_ptrs.push_back(&buffs[i].front());
    }

    // Create one ofstream object per channel
    // (use shared_ptr because ofstream is non-copyable)
    std::vector<boost::shared_ptr<std::ofstream>> outfiles;
    for (size_t i = 0; i < buffs.size(); i++) {
        const std::string this_filename = generate_out_filename(file, buffs.size(), i);
        outfiles.push_back(boost::shared_ptr<std::ofstream>(
            new std::ofstream(this_filename.c_str(), std::ofstream::binary)));
    }
    UHD_ASSERT_THROW(outfiles.size() == buffs.size());
    UHD_ASSERT_THROW(buffs.size() == rx_channel_nums.size());
    bool overflow_message = true;
    double timeout =
        settling_time + 0.1f; // expected settling time + padding for first recv

    // setup streaming
    uhd::stream_cmd_t stream_cmd((num_requested_samples == 0)
                                     ? uhd::stream_cmd_t::STREAM_MODE_START_CONTINUOUS
                                     : uhd::stream_cmd_t::STREAM_MODE_NUM_SAMPS_AND_DONE);
    stream_cmd.num_samps  = num_requested_samples;
    stream_cmd.stream_now = false;
    stream_cmd.time_spec  = uhd::time_spec_t(settling_time);
    rx_stream->issue_stream_cmd(stream_cmd);

    while (not stop_signal_called
           and (num_requested_samples > num_total_samps or num_requested_samples == 0)) {
        size_t num_rx_samps = rx_stream->recv(buff_ptrs, samps_per_buff, md, timeout);
        timeout             = 0.1f; // small timeout for subsequent recv

        if (md.error_code == uhd::rx_metadata_t::ERROR_CODE_TIMEOUT) {
            std::cout << boost::format("Timeout while streaming") << std::endl;
            rx_any_error = true;
            break;
        }
        if (md.error_code == uhd::rx_metadata_t::ERROR_CODE_OVERFLOW) {
            rx_any_error = true;
            if (overflow_message) {
                overflow_message = false;
                std::cerr
                    << boost::format(
                           "Got an overflow indication. Please consider the following:\n"
                           "  Your write medium must sustain a rate of %fMB/s.\n"
                           "  Dropped samples will not be written to the file.\n"
                           "  Please modify this example for your purposes.\n"
                           "  This message will not appear again.\n")
                           % (usrp->get_rx_rate() * sizeof(samp_type) / 1e6);
            }
            continue;
        }
        if (md.error_code != uhd::rx_metadata_t::ERROR_CODE_NONE) {
            rx_any_error = true;
            throw std::runtime_error(
                str(boost::format("Receiver error %s") % md.strerror()));
        }

        num_total_samps += num_rx_samps;

        for (size_t i = 0; i < outfiles.size(); i++) {
            outfiles[i]->write(
                (const char*)buff_ptrs[i], num_rx_samps * sizeof(samp_type));
        }
    }

    // Shut down receiver
    stream_cmd.stream_mode = uhd::stream_cmd_t::STREAM_MODE_STOP_CONTINUOUS;
    rx_stream->issue_stream_cmd(stream_cmd);

    // Close files
    for (size_t i = 0; i < outfiles.size(); i++) {
        outfiles[i]->close();
    }
}


/***********************************************************************
 * Main function
 **********************************************************************/
int UHD_SAFE_MAIN(int argc, char* argv[])
{
    // transmit variables to be set by po
    std::string tx_args, wave_type, tx_ant, tx_subdev, ref, otw, cpu_fmt, tx_channels;
    double tx_rate, tx_freq, tx_gain, wave_freq, tx_bw;
    float ampl;

    // receive variables to be set by po
    std::string rx_args, tx_basepath, rx_basepath, type, rx_ant, rx_subdev, rx_channels;
    size_t total_num_samps, spb;
    double rx_rate, rx_freq, rx_gain, rx_bw;
    double rx_settling, tx_settling;

    // setup the program options
    po::options_description desc("Allowed options");
    // clang-format off
    desc.add_options()
        ("help", "help message")
        ("tx-args", po::value<std::string>(&tx_args)->default_value(""), "uhd transmit device address args")
        ("rx-args", po::value<std::string>(&rx_args)->default_value(""), "uhd receive device address args")
        ("tx-file", po::value<std::string>(&tx_basepath)->default_value("usrp_samples.dat"), "name of the file to read binary samples from")
        ("rx-file", po::value<std::string>(&rx_basepath)->default_value("usrp_samples.dat"), "name of the file to write binary samples to")
        ("type", po::value<std::string>(&type)->default_value("short"), "sample type in file: double, float, or short")
        ("nsamps", po::value<size_t>(&total_num_samps)->default_value(0), "total number of samples to receive")
        ("tx-settling", po::value<double>(&tx_settling)->default_value(double(0.5)), "settling time (seconds) before transmitting")
        ("rx-settling", po::value<double>(&rx_settling)->default_value(double(0.2)), "settling time (seconds) before receiving")
        ("spb", po::value<size_t>(&spb)->default_value(0), "samples per buffer, 0 for default")
        ("tx-rate", po::value<double>(&tx_rate), "rate of transmit outgoing samples")
        ("rx-rate", po::value<double>(&rx_rate), "rate of receive incoming samples")
        ("tx-freq", po::value<double>(&tx_freq), "transmit RF center frequency in Hz")
        ("rx-freq", po::value<double>(&rx_freq), "receive RF center frequency in Hz")
        ("ampl", po::value<float>(&ampl)->default_value(float(0.3)), "amplitude of the waveform [0 to 0.7]")
        ("tx-gain", po::value<double>(&tx_gain), "gain for the transmit RF chain")
        ("rx-gain", po::value<double>(&rx_gain), "gain for the receive RF chain")
        ("tx-ant", po::value<std::string>(&tx_ant), "transmit antenna selection")
        ("rx-ant", po::value<std::string>(&rx_ant), "receive antenna selection")
        ("tx-subdev", po::value<std::string>(&tx_subdev), "transmit subdevice specification")
        ("rx-subdev", po::value<std::string>(&rx_subdev), "receive subdevice specification")
        ("tx-bw", po::value<double>(&tx_bw), "analog transmit filter bandwidth in Hz")
        ("rx-bw", po::value<double>(&rx_bw), "analog receive filter bandwidth in Hz")
        ("wave-type", po::value<std::string>(&wave_type)->default_value("CONST"), "waveform type (CONST, SQUARE, RAMP, SINE)")
        ("wave-freq", po::value<double>(&wave_freq)->default_value(0), "waveform frequency in Hz")
        ("ref", po::value<std::string>(&ref)->default_value("internal"), "clock reference (internal, external, mimo)")
        ("otw", po::value<std::string>(&otw)->default_value("sc16"), "specify the over-the-wire sample mode")
        ("cpu_fmt", po::value<std::string>(&otw)->default_value("fc32"), "specify the cpu format for the samples")
        ("tx-channels", po::value<std::string>(&tx_channels)->default_value("0"), "which TX channel(s) to use (specify \"0\", \"1\", \"0,1\", etc)")
        ("rx-channels", po::value<std::string>(&rx_channels)->default_value("0"), "which RX channel(s) to use (specify \"0\", \"1\", \"0,1\", etc)")
        ("tx-int-n", "tune USRP TX with integer-N tuning")
        ("rx-int-n", "tune USRP RX with integer-N tuning")
    ;
    // clang-format on
    po::variables_map vm;
    po::store(po::parse_command_line(argc, argv, desc), vm);
    po::notify(vm);

    // print the help message
    if (vm.count("help")) {
        std::cout << boost::format("UHD TXRX Loopback to File %s") % desc << std::endl;
        return ~0;
    }

    // create a usrp device
    std::cout << std::endl;
    std::cout << boost::format("Creating the transmit usrp device with: %s...") % tx_args
              << std::endl;
    uhd::usrp::multi_usrp::sptr tx_usrp = uhd::usrp::multi_usrp::make(tx_args);
    std::cout << std::endl;
    // std::cout << boost::format("Creating the receive usrp device with: %s...") % rx_args
    //           << std::endl;
    // uhd::usrp::multi_usrp::sptr rx_usrp = uhd::usrp::multi_usrp::make(rx_args);
    uhd::usrp::multi_usrp::sptr rx_usrp = tx_usrp; // USRP X310 NI-RIO

    // always select the subdevice first, the channel mapping affects the other settings
    if (vm.count("tx-subdev"))
        tx_usrp->set_tx_subdev_spec(tx_subdev);
    if (vm.count("rx-subdev"))
        rx_usrp->set_rx_subdev_spec(rx_subdev);

    // std::cout << tx_usrp->get_tx_num_channels() << std::endl;
    // std::cout << tx_usrp->get_rx_num_channels() << std::endl;
    // return 0;

    // detect which channels to use
    std::vector<std::string> tx_channel_strings;
    std::vector<size_t> tx_channel_nums;
    boost::split(tx_channel_strings, tx_channels, boost::is_any_of("\"',"));
    for (size_t ch = 0; ch < tx_channel_strings.size(); ch++) {
        size_t chan = std::stoi(tx_channel_strings[ch]);
        if (chan >= tx_usrp->get_tx_num_channels()) {
            throw std::runtime_error("Invalid TX channel(s) specified.");
        } else
            tx_channel_nums.push_back(std::stoi(tx_channel_strings[ch]));
    }
    std::vector<std::string> rx_channel_strings;
    std::vector<size_t> rx_channel_nums;
    boost::split(rx_channel_strings, rx_channels, boost::is_any_of("\"',"));
    for (size_t ch = 0; ch < rx_channel_strings.size(); ch++) {
        size_t chan = std::stoi(rx_channel_strings[ch]);
        if (chan >= rx_usrp->get_rx_num_channels()) {
            throw std::runtime_error("Invalid RX channel(s) specified.");
        } else
            rx_channel_nums.push_back(std::stoi(rx_channel_strings[ch]));
    }

    // std::cout << "tx_channel_nums" << std::endl;
    // // Print all elements in vector
    // std::for_each(  tx_channel_nums.begin(),
    //                 tx_channel_nums.end(),
    //                 [](const auto & elem ) {
    //                         std::cout<<elem<<" ";
    //                 });
    // std::cout << "rx_channel_nums" << std::endl;
    // // Print all elements in vector
    // std::for_each(  rx_channel_nums.begin(),
    //                 rx_channel_nums.end(),
    //                 [](const auto & elem ) {
    //                         std::cout<<elem<<" ";
    //                 });
    // return 0;

    // Lock mboard clocks
    if (vm.count("ref")) {
        tx_usrp->set_clock_source(ref);
        rx_usrp->set_clock_source(ref);
    }

    std::cout << boost::format("Using TX Device: %s") % tx_usrp->get_pp_string()
              << std::endl;
    // std::cout << boost::format("Using RX Device: %s") % rx_usrp->get_pp_string()
    //           << std::endl;

    // set the transmit sample rate
    if (not vm.count("tx-rate")) {
        std::cerr << "Please specify the transmit sample rate with --tx-rate"
                  << std::endl;
        return ~0;
    }
    std::cout << boost::format("Setting TX Rate: %f Msps...") % (tx_rate / 1e6)
              << std::endl;
    tx_usrp->set_tx_rate(tx_rate);
    std::cout << boost::format("Actual TX Rate: %f Msps...")
                     % (tx_usrp->get_tx_rate() / 1e6)
              << std::endl
              << std::endl;

    // set the receive sample rate
    if (not vm.count("rx-rate")) {
        std::cerr << "Please specify the sample rate with --rx-rate" << std::endl;
        return ~0;
    }
    std::cout << boost::format("Setting RX Rate: %f Msps...") % (rx_rate / 1e6)
              << std::endl;
    rx_usrp->set_rx_rate(rx_rate);
    std::cout << boost::format("Actual RX Rate: %f Msps...")
                     % (rx_usrp->get_rx_rate() / 1e6)
              << std::endl
              << std::endl;

    // set the transmit center frequency
    if (not vm.count("tx-freq")) {
        std::cerr << "Please specify the transmit center frequency with --tx-freq"
                  << std::endl;
        return ~0;
    }

    for (size_t ch = 0; ch < tx_channel_nums.size(); ch++) {
        size_t channel = tx_channel_nums[ch];
        if (tx_channel_nums.size() > 1) {
            std::cout << "Configuring TX Channel " << channel << std::endl;
        }
        std::cout << boost::format("Setting TX Freq: %f MHz...") % (tx_freq / 1e6)
                  << std::endl;
        uhd::tune_request_t tx_tune_request(tx_freq);
        if (vm.count("tx-int-n"))
            tx_tune_request.args = uhd::device_addr_t("mode_n=integer");
        tx_usrp->set_tx_freq(tx_tune_request, channel);
        std::cout << boost::format("Actual TX Freq: %f MHz...")
                         % (tx_usrp->get_tx_freq(channel) / 1e6)
                  << std::endl
                  << std::endl;

        // set the rf gain
        if (vm.count("tx-gain")) {
            std::cout << boost::format("Setting TX Gain: %f dB...") % tx_gain
                      << std::endl;
            tx_usrp->set_tx_gain(tx_gain, channel);
            std::cout << boost::format("Actual TX Gain: %f dB...")
                             % tx_usrp->get_tx_gain(channel)
                      << std::endl
                      << std::endl;
        }

        // set the analog frontend filter bandwidth
        if (vm.count("tx-bw")) {
            std::cout << boost::format("Setting TX Bandwidth: %f MHz...") % (tx_bw/1e6)
                      << std::endl;
            tx_usrp->set_tx_bandwidth(tx_bw, channel);
            std::cout << boost::format("Actual TX Bandwidth: %f MHz...")
                             % (tx_usrp->get_tx_bandwidth(channel)/1e6)
                      << std::endl
                      << std::endl;
        }

        // set the antenna
        if (vm.count("tx-ant"))
            tx_usrp->set_tx_antenna(tx_ant, channel);
    }

    for (size_t ch = 0; ch < rx_channel_nums.size(); ch++) {
        size_t channel = rx_channel_nums[ch];
        if (rx_channel_nums.size() > 1) {
            std::cout << "Configuring RX Channel " << channel << std::endl;
        }

        // set the receive center frequency
        if (not vm.count("rx-freq")) {
            std::cerr << "Please specify the center frequency with --rx-freq"
                      << std::endl;
            return ~0;
        }
        std::cout << boost::format("Setting RX Freq: %f MHz...") % (rx_freq / 1e6)
                  << std::endl;
        uhd::tune_request_t rx_tune_request(rx_freq);
        if (vm.count("rx-int-n"))
            rx_tune_request.args = uhd::device_addr_t("mode_n=integer");
        rx_usrp->set_rx_freq(rx_tune_request, channel);
        std::cout << boost::format("Actual RX Freq: %f MHz...")
                         % (rx_usrp->get_rx_freq(channel) / 1e6)
                  << std::endl
                  << std::endl;

        // set the receive rf gain
        if (vm.count("rx-gain")) {
            std::cout << boost::format("Setting RX Gain: %f dB...") % rx_gain
                      << std::endl;
            rx_usrp->set_rx_gain(rx_gain, channel);
            std::cout << boost::format("Actual RX Gain: %f dB...")
                             % rx_usrp->get_rx_gain(channel)
                      << std::endl
                      << std::endl;
        }

        // set the receive analog frontend filter bandwidth
        if (vm.count("rx-bw")) {
            std::cout << boost::format("Setting RX Bandwidth: %f MHz...") % (rx_bw / 1e6)
                      << std::endl;
            rx_usrp->set_rx_bandwidth(rx_bw, channel);
            std::cout << boost::format("Actual RX Bandwidth: %f MHz...")
                             % (rx_usrp->get_rx_bandwidth(channel) / 1e6)
                      << std::endl
                      << std::endl;
        }

        // set the receive antenna
        if (vm.count("rx-ant"))
            rx_usrp->set_rx_antenna(rx_ant, channel);
    }

    // for the const wave, set the wave freq for small samples per period
    if (wave_freq == 0 and wave_type == "CONST") {
        wave_freq = tx_usrp->get_tx_rate() / 2;
    }

    // error when the waveform is not possible to generate
    if (std::abs(wave_freq) > tx_usrp->get_tx_rate() / 2) {
        throw std::runtime_error("wave freq out of Nyquist zone");
    }
    if (tx_usrp->get_tx_rate() / std::abs(wave_freq) > wave_table_len / 2) {
        throw std::runtime_error("wave freq too small for table");
    }

    // pre-compute the waveform values
    // const wave_table_class wave_table(wave_type, ampl);
    // const size_t step =
    //     boost::math::iround(wave_freq / tx_usrp->get_tx_rate() * wave_table_len);
    // size_t index = 0;


    // return 0;

    std::this_thread::sleep_for(std::chrono::milliseconds(10));
    // Check Ref and LO Lock detect
    std::vector<std::string> tx_sensor_names, rx_sensor_names;
    tx_sensor_names = tx_usrp->get_tx_sensor_names(0);
    if (std::find(tx_sensor_names.begin(), tx_sensor_names.end(), "lo_locked")
        != tx_sensor_names.end()) {
        uhd::sensor_value_t lo_locked = tx_usrp->get_tx_sensor("lo_locked", 0);
        std::cout << boost::format("Checking TX: %s ...") % lo_locked.to_pp_string()
                  << std::endl;
        UHD_ASSERT_THROW(lo_locked.to_bool());
    }
    rx_sensor_names = rx_usrp->get_rx_sensor_names(0);
    if (std::find(rx_sensor_names.begin(), rx_sensor_names.end(), "lo_locked")
        != rx_sensor_names.end()) {
        uhd::sensor_value_t lo_locked = rx_usrp->get_rx_sensor("lo_locked", 0);
        std::cout << boost::format("Checking RX: %s ...") % lo_locked.to_pp_string()
                  << std::endl;
        UHD_ASSERT_THROW(lo_locked.to_bool());
    }

    tx_sensor_names = tx_usrp->get_mboard_sensor_names(0);
    if ((ref == "mimo")
        and (std::find(tx_sensor_names.begin(), tx_sensor_names.end(), "mimo_locked")
                != tx_sensor_names.end())) {
        uhd::sensor_value_t mimo_locked = tx_usrp->get_mboard_sensor("mimo_locked", 0);
        std::cout << boost::format("Checking TX: %s ...") % mimo_locked.to_pp_string()
                  << std::endl;
        UHD_ASSERT_THROW(mimo_locked.to_bool());
    }
    if ((ref == "external")
        and (std::find(tx_sensor_names.begin(), tx_sensor_names.end(), "ref_locked")
                != tx_sensor_names.end())) {
        uhd::sensor_value_t ref_locked = tx_usrp->get_mboard_sensor("ref_locked", 0);
        std::cout << boost::format("Checking TX: %s ...") % ref_locked.to_pp_string()
                  << std::endl;
        UHD_ASSERT_THROW(ref_locked.to_bool());
    }

    rx_sensor_names = rx_usrp->get_mboard_sensor_names(0);
    if ((ref == "mimo")
        and (std::find(rx_sensor_names.begin(), rx_sensor_names.end(), "mimo_locked")
                != rx_sensor_names.end())) {
        uhd::sensor_value_t mimo_locked = rx_usrp->get_mboard_sensor("mimo_locked", 0);
        std::cout << boost::format("Checking RX: %s ...") % mimo_locked.to_pp_string()
                  << std::endl;
        UHD_ASSERT_THROW(mimo_locked.to_bool());
    }
    if ((ref == "external")
        and (std::find(rx_sensor_names.begin(), rx_sensor_names.end(), "ref_locked")
                != rx_sensor_names.end())) {
        uhd::sensor_value_t ref_locked = rx_usrp->get_mboard_sensor("ref_locked", 0);
        std::cout << boost::format("Checking RX: %s ...") % ref_locked.to_pp_string()
                  << std::endl;
        UHD_ASSERT_THROW(ref_locked.to_bool());
    }

    if (total_num_samps == 0) {
        std::signal(SIGINT, &sig_int_handler);
        std::cout << "Press Ctrl + C to stop streaming..." << std::endl;
    }

    // output_reg_values("FP0", tx_usrp, 10);
    // setup GPIO trigger
    usrp_gpio_arm_trigger(tx_usrp);
    // output_reg_values("FP0", tx_usrp, 10);
    // return 0;

    // reset usrp time to prepare for transmit/receive
    std::cout << boost::format("Setting device timestamp to 0...") << std::endl;
    tx_usrp->set_time_now(uhd::time_spec_t(0.0));
    rx_usrp->set_time_now(uhd::time_spec_t(0.0));

    // create a transmit streamer
    // linearly map channels (index0 = channel0, index1 = channel1, ...)
    
    // cpu format
    // fc64 - complex<double>
    // fc32 - complex<float>
    // sc16 - complex<int16_t>
    // sc8 - complex<int8_t>
    cpu_fmt = "fc32";
    otw = "sc16";
    uhd::stream_args_t stream_args(cpu_fmt, otw);
    stream_args.channels             = tx_channel_nums;
    uhd::tx_streamer::sptr tx_stream = tx_usrp->get_tx_stream(stream_args);

    // allocate a buffer which we re-use for each channel
    if (spb == 0)
        spb = tx_stream->get_max_num_samps();

    // std::vector<std::complex<float>> buff(spb);
    // int num_channels = tx_channel_nums.size();

    // setup the metadata flags
    // uhd::tx_metadata_t md;
    // md.start_of_burst = true;
    // md.end_of_burst   = false;
    // md.has_time_spec  = true;
    // md.time_spec = uhd::time_spec_t(tx_settling); // give us 0.5 seconds to fill the tx buffers

    // start transmit worker thread
    boost::thread_group transmit_thread;
    // transmit_thread.create_thread(boost::bind(&transmit_worker, buff, wave_table, tx_stream, md, step, index, num_channels));
    // transmit_thread.create_thread(boost::bind(&send_from_file, tx_stream, std::string(tx_basepath), 1000, num_channels, md));
    // transmit_thread.create_thread(boost::bind(&send_from_file, tx_stream, std::string(tx_basepath), spb, num_channels, md));
    std::cout << boost::format(" cpu_fmt: %s, otw: %s\n") % cpu_fmt % otw ;

    if (cpu_fmt == "fc32" and otw == "sc16") {
        transmit_thread.create_thread(boost::bind(&send_from_file, tx_stream, std::string(tx_basepath), tx_settling));
        recv_to_file<std::complex<float>>(rx_usrp, cpu_fmt, otw, rx_basepath, spb, total_num_samps, rx_settling, rx_channel_nums);
    }
    else if (cpu_fmt == "sc8" and otw == "sc8") {
        // // size_t samps_per_buff = tx_stream->get_max_num_samps();
        // std::ifstream infile(tx_basepath.c_str(), std::ifstream::binary);
        // infile.seekg (0, infile.end);
        // int length = infile.tellg();
        // infile.seekg (0, infile.beg);
        // std::vector<std::complex<int8_t>> buff(ceil((double)length/sizeof(std::complex<int8_t>)), std::complex<int8_t>(0.0, 0.0));    
        // infile.read((char*)&buff.front(), length);
        // infile.close();

        // // std::cout << "samps_per_buff " << samps_per_buff << ".\n";
        // std::cout << "Tx file has " << length << " bytes.\n";
        // std::cout << "buff size " << buff.size() << " bytes.\n";
        // // std::for_each(  buff.begin(), buff.end(),
        // //                 [](const auto & elem ) {
        // //                         std::cout<< (float)std::real(elem)<< " " << (float)std::imag(elem)<<"\n";
        // //                 });
        
        // // std::cout << "Number of batch " << ceil((double)buff.size()/(samps_per_buff*sizeof(buff[0]))) << "\n";
        // // std::cout << sizeof(std::complex<int8_t>) << " " << sizeof(buff[0]) << std::endl;
        // // return 0;

        // transmit_thread.create_thread(boost::bind(&send_from_file, tx_stream, buff, tx_settling));
        // recv_to_file<std::complex<int8_t>>(rx_usrp, cpu_fmt, otw, rx_basepath, spb, total_num_samps, rx_settling, rx_channel_nums);
    }
    else {
        std::cout << boost::format("not supported cpu_fmt: %s, otw: %s\n") % cpu_fmt % otw ;
        return 1;
    }
    
    // // recv to file
    // if (type == "double")
    //     recv_to_file<std::complex<double>>(
    //         rx_usrp, "fc64", otw, rx_basepath, spb, total_num_samps, rx_settling, rx_channel_nums);
    // else if (type == "float")
    //     recv_to_file<std::complex<float>>(
    //         rx_usrp, "fc32", otw, rx_basepath, spb, total_num_samps, rx_settling, rx_channel_nums);
    // else if (type == "short")
    //     recv_to_file<std::complex<short>>(
    //         rx_usrp, "sc16", otw, rx_basepath, spb, total_num_samps, rx_settling, rx_channel_nums);
    // else {
    //     // clean up transmit worker
    //     stop_signal_called = true;
    //     transmit_thread.join_all();
    //     throw std::runtime_error("Unknown type " + type);
    // }

    // clean up transmit worker
    stop_signal_called = true;
    transmit_thread.join_all();

    // finished
    std::cout << std::endl << "Done!" << std::endl << std::endl;
    if (tx_any_error || rx_any_error)
        return 1;
    else
        return EXIT_SUCCESS;
}
