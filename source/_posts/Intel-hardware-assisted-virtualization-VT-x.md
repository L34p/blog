---
title: 인텔의 하드웨어 가상화 기술 VT-x
author: L34P
date: 2017-02-02 10:41:21
tags:
- Virtual Machine
- Architecture
- System
---

## Motivation
이번 포스팅에서는 인텔의 하드웨어 가상화 지원 기술인 VT-x 에 대해 다뤄보려고 합니다. [이전 포스팅](/blog/2017/01/05/What-is-virtualizable-ISA/) 에서 다뤘듯이 인텔의 x86 아키텍처는 [**포펙과 골드버그의 가상화 요구**](https://en.wikipedia.org/wiki/Popek_and_Goldberg_virtualization_requirements)를 만족하지 못해 가상머신을 추가하기가 어려웠습니다. 하드웨어적인 가상화 지원이 나오기 이전에는 이러한 문제점을 해결하기 위해 아래와 같은 소프트웨어적인 해결책이 제시되었습니다.  

<!-- more -->
  
- ***Binary Translation***
  - Dynamic 하게 실행도중 guest OS의 바이너리를 수정, 가상화에 문제가 되는 명령어들을 변환한 후 실행
    - 장점: 소스코드 변경없이 많은 OS 지원가능
    - 단점: Translation overhead
  - e.g. VMware
- ***Paravirtualization***
  - Guest OS 의 소스코드를 변경하여 가상화 할 수 있도록 인터페이스를 만듬
    - 장정: 고성능
    - 단점: 소스코드를 수정해야하므로 지원가능한 OS 가 한정됨
  - e.g. Xen
  
하지만 이러한 소프트웨어적인 해결책은 결국 한계점이 존재하였고, 한계점을 극복하고 위에서 언급한 소프트웨어적인 해결책 없이 더욱 간결하고 고성능의 가상머신 모니터 (VMM) 의 구현을 가능하게 하기 위해 인텔의 VT-x, AMD의 AMD-V 등 하드웨어적인 가상화 지원이 등장하게 됩니다.
  
## Intel hardware-assisted virtualization VT-x
> 그렇다면 인텔 VT-x 는 대체 무엇이며,  인텔은 가상화 문제를 어떻게 해결하였을까요?

### VMX root 모드와 VMX non-root 모드
우선 VT-x 에서는 VMX root 모드와 VMX non-root 모드라는 두 가지 새로운 CPU 작동 모드가 추가되었습니다. 여기서 VMX 는 Virtual Machine Extensions 를 나타내며 VMX root 모드는 VMM 을 실행하는데 사용되고, VMX non-root 모드는 VMM 위에서 실행되는 guest OS를 실행하는데 사용됩니다. 또한 두 모드는 각각 별개의 privilege ring 을 가집니다. 즉, 두 가지 모드가 각각 ring 0 부터 ring 3 까지 모두 가지고 이로 인해 guest OS 가 ring 0 에서 실행될 수 있게 됩니다.
  
  - ***VMX root 모드***
    - VMM 을 실행하는데 사용   
    - VT-x를 사용하지 않을 때의 일반적인 작동 방식과 거의 같음  
  - ***VMX non-root 모드***
    - VMM 위에서 돌아가는 guest OS 를 실행하는데 사용  
    - 많은 명령어와 이벤트들이 VM exit을 수행하도록 작동 방식이 바뀜  
    - 몇 가지 특정 명령어 들은 VMX non-root 모드에서 실행될 수 없으며 VMX root 모드에서 실행되도록 VM exit이 강제됨  
  
### VMX transition (VM entry and VM exit)
![VMX-Transition](/blog/img/VMM-LifeCycle.png "출처: Intel 64 and IA-32 Architectures Software Developer’s Manual, Volume 3C")

또한 VT-x 에서는 VMX root 모드와 VMX non-root 모드 사이의 전환을 위해 VM entry 와 VM exit 이라는 새로운 transition 이 추가됩니다. 이러한 VMX transition 은 이후에 설명할 VMCS (Virtual-Machine Control Structure) 라는 새로운 자료구조에 의해 관리됩니다.  
  
  - ***VM entry***
    - VMM (VMX root) -> guest OS (VMX non-root)
    - VMCS 에서 guest 정보를 가져옴
  - ***VM exit***
    - Guest OS (VMX non-root) -> VMM (VMX root)
    - VMCS 에 guest 정보를 저장하고, host 정보를 가져옴

### VMCS (Virtual-Machine Control Structure)
VMCS 는 가상화 환경을 지원하기 위해 새로 추가된 자료구조 입니다. VMCS 는 VMX non-root 모드에서의 작동 방식과 VMX transition 등을 관리하며 아래와 같은 필드들이 존재합니다.

  - ***Guest-State Area***
    - Guest OS 의 상태 및 정보를 저장하기 위해 사용
    - VMX transition 시 자동으로 저장 및 불러옴
  - ***Host-State Area***
    - Host 의 상태 및 정보를 저장하기 위해 사용
    - VM exit 수행시 자동으로 불러옴
  - ***VM-Execution Control Fields***
    - VMX non-root 모드에서의 프로세서의 작동방식 제어
    - VMX non-root 모드에서 VM exit 을 수행하게 하는 명령어나 이벤트 등을 설정할 수 있음
  - ***VM-exit Control Fields***
    - VM exit 작동방식을 제어
  - ***VM-entry Control Fields***
    - VM entry 작동방식을 제어
  - ***VM-exit Information Fields***
    - 가장 최근에 일어난 VM exit에 대해 VM exit 이 일어난 이유 등 VM exit 에 대한 정보를 저장
    - 이 필드를 보고 VMM 에서는 VM exit 이 일어난 이유에 따라 적절한 처리가 가능함
    
## Summary
![Intel-VT-x](/blog/img/Intel_VT-x.png)

결국 간단히 요약하면 VT-x는 guest OS의 실행을 위해 별개의 privilege ring 을 가지는 새로운 CPU 모드를 추가하여 guest OS가 ring 0 에서 실행될 수 있도록 하고, VMM의 관여가 필요 없는 명령어 및 이벤트는 하드웨어를 통해 직접 바로 처리될 수 있도록 하며 VMM의 관여가 필요한 경우 VMX transition (trap) 을 통해 제어하여 가상화를 지원한다고 할 수 있을 것 같습니다.
  
## References
1. [Intel Virtualization Technology: Hardware Support for Efficient Processor Virtualization](http://www.intel.com/content/dam/www/public/us/en/documents/research/2006-vol10-iss-3-intel-technology-journal.pdf)
2. [Intel 64 and IA-32 Architectures Software Developer’s Manual, Volume 3C](http://www.intel.com/content/dam/www/public/us/en/documents/manuals/64-ia-32-architectures-software-developer-vol-3c-part-3-manual.pdf)
3. https://en.wikipedia.org/wiki/X86_virtualization
4. http://blog.yunochi.co.kr/?p=244
5. [Hardware-assisted Virtualization PPT slide](https://www.google.co.kr/url?sa=t&rct=j&q=&esrc=s&source=web&cd=1&ved=0ahUKEwj9h6zB0vHRAhVLJZQKHYMwD4QQFggfMAA&url=http%3A%2F%2Fwww.cs.cmu.edu%2F~412%2Flectures%2FL04_VTx.pptx&usg=AFQjCNHPMFD0TVO3SCifzkvq4q7R406lNw&sig2=fI_9nF_HYh19zeg4XKwTVQ&bvm=bv.146073913,d.dGo&cad=rja)
6. https://www.usenix.org/system/files/login/articles/105498-Revelle.pdf 
