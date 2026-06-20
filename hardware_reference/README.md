# Hardware reference

[English](#english) | [中文](#中文)

## English

This folder contains hardware-side reference materials for understanding the
LightThief setup.

### Contents

```text
gnuradio/       GNU Radio flowgraphs for CW transmission and reflected-signal observation
matlab/         MATLAB helper for reading IQ signal strength
circuit/        Tag circuit photo
```

### Circuit

LightThief uses a simple tag structure: a photodiode (PD) coupled to a small
antenna. As a prototype, a Mini PCI/PCI-E antenna can be used, such as an
internal Wi-Fi/Bluetooth antenna. Choose the PD according to the wavelength of
the light source. Solder the PD in the middle of the antenna structure, and do
not cut off the feedline.

### GNU Radio and MATLAB helpers

The GNU Radio flowgraphs are reference flowgraphs for generating a continuous
wave and observing the reflected signal with an SDR/USRP setup. The MATLAB
helper reads complex `float32` IQ samples and estimates signal strength.

## 中文

本文件夹包含用于理解 LightThief 搭建方式的硬件侧参考材料。

### 内容

```text
gnuradio/       用于连续波发送和反射信号观察的 GNU Radio flowgraph
matlab/         用于读取 IQ 信号强度的 MATLAB 辅助函数
circuit/        tag 电路照片
```

### 电路

LightThief 的 tag 结构很简单：将光电二极管（PD）耦合到一个小天线上。原型可以使用
Mini PCI/PCI-E 天线，例如笔记本内置 Wi-Fi/Bluetooth 天线。PD 可以根据光源波长选择。
如图所示，将 PD 焊接在天线结构中间，并且不要剪断馈线。

### GNU Radio 和 MATLAB 辅助代码

GNU Radio flowgraph 用于参考连续波发送以及通过 SDR/USRP 观察反射信号。MATLAB 辅助函数
读取 complex `float32` IQ 样本并估计信号强度。
