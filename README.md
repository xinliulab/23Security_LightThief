# LightThief

[English](#english) | [中文](#中文)

## English

End-to-end MATLAB simulations for **LightThief**, the system described in
the USENIX Security 2023 paper *Your Optical Communication Information Is
Stolen behind the Wall*.

This release focuses on two ideas:

1. **Reflection insight:** a sinusoidal incident carrier multiplied by a
   switching reflection coefficient produces translated spectral components
   and odd-harmonic sidebands.
2. **End-to-end communication:** text is encoded into Manchester-OOK light; the
   data-coded light switches the tag reflection; the reflected RF carries the
   data on square-wave harmonics, then the receiver selects a harmonic,
   synchronizes, and decodes the bytes.

The release is MATLAB-only.

### What is included

```text
insight_demo/       Simplified sine-wave reflection and harmonic demo
end_to_end/         Complete encoder, channel, receiver, and decoder
hardware_reference/ Circuit photo and SDR/USRP reference flowgraphs
```

For the easiest introduction to the signal-processing path, open
[`end_to_end/walkthrough.html`](end_to_end/walkthrough.html) in a web browser.

### Quick start: MATLAB

The MATLAB implementation is the recommended starting point.

#### Requirements

- MATLAB R2018b or newer
- Signal Processing Toolbox for `resample`, `decimate`, and plotting helpers

#### 1. Run the physical insight demo

```matlab
cd insight_demo
run_sine_reflection_demo
```

This generates `figures/sine_reflection_spectrum.png` and shows:

- the incident sinusoidal carrier;
- the tag switching waveform;
- the modulated reflection;
- spectral components around `f_c +/- k f_tag`, for odd `k`.

#### 2. Test the end-to-end implementation

```matlab
cd end_to_end
test_sim
```

Expected result:

```text
[PASS] coding round-trip (no DSP) recovers text
[PASS] coding round-trip BER == 0
[PASS] Hamming corrects every single-bit error in all 256 bytes
[PASS] baseband-equivalent chain @10 dB decodes 'LightThief'
[PASS] baseband-equivalent chain BER == 0
[PASS] physical passband (harmonic-extracted) chain @15 dB decodes text
[PASS] comb has carrier at fc
[PASS] comb has first harmonic at fc+fo

All tests passed.
```

#### 3. Run the complete demo

```matlab
run_demo
run_demo('Hello LightThief')
run_ber
```

The scripts generate a harmonic-comb spectrum, recovered BPSK constellation,
and BER curve under carrier-frequency offset, phase offset, timing drift, and
AWGN.

### Signal chain

```text
ASCII text
  -> Hamming(12,8) + overall parity
  -> 10-bit preamble + Manchester-OOK optical waveform
  -> tag switching by that same data-coded light
  -> reflected RF = ambient carrier multiplied by the optical square wave
  -> harmonic comb at fc +/- m*fo, m = 1,3,5,...
  -> CFO + phase offset + timing drift + AWGN
  -> select and downconvert the first reflected harmonic
  -> matched filter and carrier/timing synchronization
  -> BPSK slicing, preamble alignment, Hamming decoding
  -> recovered text
```

### Relation to SDR deployment

The MATLAB code is modular: waveform generation, channel input, synchronization,
and decoding are separate stages. Readers may use the synchronization and
decoder modules as references when integrating their own SDR acquisition
pipeline.

### License and commercial use

This software is licensed under the
[PolyForm Noncommercial License 1.0.0](LICENSE).

Noncommercial academic research, education, personal study, experimentation,
and testing are permitted under that license. Commercial use - including product
development, commercial services, or use with anticipated commercial
application - requires a separate written license from the relevant rights
holder.

For commercial licensing or patent-related inquiries, contact the repository
maintainers and the relevant institutional technology-transfer office.

### Citation

If this code supports an academic publication, please cite:

```bibtex
@inproceedings {lightthief,
	author = {Xin Liu and Wei Wang and Guanqun Song and Ting Zhu},
	title = {{LightThief}: Your Optical Communication Information is Stolen behind the Wall},
	booktitle = {32nd USENIX Security Symposium (USENIX Security 23)},
	year = {2023},
	isbn = {978-1-939133-37-3},
	address = {Anaheim, CA},
	pages = {5325--5339},
	url = {https://www.usenix.org/conference/usenixsecurity23/presentation/liu-xin},
	publisher = {USENIX Association},
	month = aug
}
```

## 中文

**LightThief** 的 MATLAB 端到端仿真代码，对应 USENIX Security 2023 论文
*Your Optical Communication Information Is Stolen behind the Wall*。

本仓库主要展示两个内容：

1. **反射机理验证：** 入射正弦载波与开关式反射系数相乘后，会产生频移后的频谱分量和奇次谐波边带。
2. **端到端通信：** 文本被编码成 Manchester-OOK 光信号；带数据的光控制 tag 的反射状态；反射 RF 在方波谐波上携带数据；接收端选择一个谐波，同步并解码出字节。

本仓库只发布 MATLAB 版本。

### 包含内容

```text
insight_demo/       简化的正弦反射与谐波演示
end_to_end/         完整的编码器、信道、接收机和解码器
hardware_reference/ 电路照片和 SDR/USRP 参考 flowgraph
```

如果想最快理解信号处理流程，可以在浏览器中打开
[`end_to_end/walkthrough.html`](end_to_end/walkthrough.html)。

### MATLAB 快速开始

建议从 MATLAB 实现开始。

#### 运行要求

- MATLAB R2018b 或更新版本
- Signal Processing Toolbox，用于 `resample`、`decimate` 和绘图辅助函数

#### 1. 运行反射机理演示

```matlab
cd insight_demo
run_sine_reflection_demo
```

该脚本生成 `figures/sine_reflection_spectrum.png`，并展示：

- 入射正弦载波；
- tag 的开关波形；
- 被调制后的反射信号；
- `f_c +/- k f_tag` 附近的频谱分量，其中 `k` 为奇数。

#### 2. 测试端到端实现

```matlab
cd end_to_end
test_sim
```

预期输出：

```text
[PASS] coding round-trip (no DSP) recovers text
[PASS] coding round-trip BER == 0
[PASS] Hamming corrects every single-bit error in all 256 bytes
[PASS] baseband-equivalent chain @10 dB decodes 'LightThief'
[PASS] baseband-equivalent chain BER == 0
[PASS] physical passband (harmonic-extracted) chain @15 dB decodes text
[PASS] comb has carrier at fc
[PASS] comb has first harmonic at fc+fo

All tests passed.
```

#### 3. 运行完整演示

```matlab
run_demo
run_demo('Hello LightThief')
run_ber
```

这些脚本会生成谐波梳状频谱、恢复后的 BPSK 星座图，以及在载波频偏、相位偏移、
定时漂移和 AWGN 下的 BER 曲线。

### 信号链路

```text
ASCII 文本
  -> Hamming(12,8) + 总体奇偶校验
  -> 10-bit 前导码 + Manchester-OOK 光波形
  -> 同一个带数据的光信号控制 tag 开关
  -> 反射 RF = 环境载波 × 光方波
  -> 在 fc +/- m*fo 处产生谐波梳，m = 1,3,5,...
  -> CFO + 相位偏移 + 定时漂移 + AWGN
  -> 选择并下变频第一个反射谐波
  -> 匹配滤波和载波/定时同步
  -> BPSK 判决、前导码对齐、Hamming 解码
  -> 恢复文本
```

### 与 SDR 部署的关系

MATLAB 代码是模块化的：波形生成、信道输入、同步和解码分别实现。读者可以在集成自己的
SDR 采集流程时参考其中的同步和解码模块。

### 许可证与商业使用

本软件使用 [PolyForm Noncommercial License 1.0.0](LICENSE)。

该许可证允许非商业的学术研究、教育、个人学习、实验和测试。商业使用——包括产品开发、
商业服务，或预期用于商业应用的使用——需要从相关权利方获得单独的书面许可。

如需商业授权或专利相关咨询，请联系仓库维护者及相关机构的技术转移办公室。

### 引用

如果本代码支持了你的学术论文，请引用：

```bibtex
@inproceedings {lightthief,
	author = {Xin Liu and Wei Wang and Guanqun Song and Ting Zhu},
	title = {{LightThief}: Your Optical Communication Information is Stolen behind the Wall},
	booktitle = {32nd USENIX Security Symposium (USENIX Security 23)},
	year = {2023},
	isbn = {978-1-939133-37-3},
	address = {Anaheim, CA},
	pages = {5325--5339},
	url = {https://www.usenix.org/conference/usenixsecurity23/presentation/liu-xin},
	publisher = {USENIX Association},
	month = aug
}
```
