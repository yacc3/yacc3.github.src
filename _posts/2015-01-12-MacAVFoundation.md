---
layout    : post
title     : MacAVFoundation
date      : 2015-01-12
category  : [CSE]
tags      : [MacOS, AVFoundation]
---


汇集一些MacOS视频音频等方面的资料，主要是AVFoundatio

[参考 apple dev AVFoundation](https://developer.apple.com/library/content/documentation/AudioVideo/Conceptual/AVFoundationPG/Articles/00_Introduction.html#//apple_ref/doc/uid/TP40010188)

<!-- more -->

# AVFoundation

Work with audiovisual assets, control device cameras, process audio, and configure system audio interactions.

主要包含一下几个Topics

- Playback and Editing
- Media Capture - Cameras and Media Capture
    - AVCaptureDevice
    - AVCaptureSession
    - AVCapturePhotoOutput
    - AVCapturePhoto
    - ...
    The AV Foundation Camera and Media Capture subsystem provides a common high-level architecture for video, photo, and audio capture services in iOS and macOS.
- Playback, Recording, Mixing and Processing
    - For simple playback and recording, use AVAudioPlayer and AVAudioRecorder.
    - For more complex audio processing, use AVAudioEngine. 
- System Audio Interaction
- Speech Synthesis


## AVCaptureDevice

代表硬件设备，为AVCaptureSession提供输入，并提供一些音频视频流控制，即配置属性。

功能，方法分类

- 发现设备
- 检查权限
- 设备Configuration
- 管理 format Focus Exposure Zoom Flash torch LowLight FrameRate Transport Characteristics LensPosition ImageExposure WhiteBalance ISO HighDynamicRangeVideo ColorSpaces
- Notifications通知

## AVCaptureSession

管理音视频流的Capture活动，并coordinates数据流。要capture数据流，需要现指定输入输出文件。

功能、方法分类

- 输入输出管理
- 管理运行时状态
- 管理sessionPreset
    use the sessionPreset property to customize the quality level, bitrate, or other settings for the output. Most common capture configurations are available through session presets; however, some specialized options (such as high frame rate) require directly setting a capture format on an AVCaptureDevice instance.
- Color Spaces 
- Notifications通知

