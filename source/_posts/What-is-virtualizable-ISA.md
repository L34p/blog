---
title: 가상화 가능한 ISA 의 조건이란?
author: L34P
date: 2017-01-05 11:03:17
tags:
- Virtual Machine
- Architecture
- System
---

최근에 인텔의 하드웨어 가상화 기술인 [VT-x](https://en.wikipedia.org/wiki/X86_virtualization#Intel_virtualization_.28VT-x.29) 에 대해 알아보면서 이러한 하드웨어적인 지원이 필요해진 이유가 꽤 흥미로워 정리해 보려고 합니다. 인텔의 가상화 지원이 나오기 이전에는 x86 아키텍처가 **"포펙과 골드버그의 가상화 요구"** 라는 가상화 가능한 ISA의 조건을 충족하지 못하여 x86 프로세서에 가상머신을 추가하기가 매우 어려웠다고 합니다.

> 그러면 **"포펙과 골드버그의 가상화 요구"** 가 대체 뭘까요?

이에 대한 답은 포펙과 골드버그의 논문 원문을 찾아보면 알 수 있습니다.
[Formal Requirements for Virtualizable Third Generation Architectures](http://dl.acm.org/citation.cfm?id=361073)

논문을 읽어보면 가상머신과 가상머신 모니터 (virtual machine monitor)의 정의 그리고 가상머신을 지원할 수 있는 하드웨어 아키텍처의 조건은 무엇인지 등에 대한 답을 하고 있습니다. 놀라운건 이 논문이 나온게 1974년도 랍니다!

여기서는 논문의 내용을 전부 다루지는 않고 가상머신을 지원할 수 있는 아키텍처의 조건에 초점을 맞춰 정리해 보려고 합니다.
혹시 관심 있으신 분은 논문에서 더욱 자세히, formal 하게 정의하고 증명하므로 논문을 읽어보는 것을 추천드립니다.

## Privileged 명령어와 Sensitive 명령어
먼저 가상머신을 지원할 수 있는 아키텍처의 조건에 대해 이야기하기 위해 CPU 명령어의 작동 방식에 대해 2가지로 분류해 보려고 합니다.

### Privileged 명령어
시스템은 user 모드 supervisor 모드 두 가지 모드를 가지고 있으며 보통 프로그램들은 user 모드에서 수행되게 되고 OS는 supervisor 모드에서 수행됩니다. 이때 privileged 명령어의 경우 user 모드에서 수행될 경우 trap 을 일으키는 명령어들을 말하게 됩니다. 여기서 trap 이란 강제로 현재 모드를 supervisor 모드로 변경하고 supervisor 모드에서 수행되는 OS가 상황에 따라 적절한 작업을 수행하는 것을 말합니다.

### Sensitive 명령어
Sensitive 명령어는 시스템의 resource를 변경하는 등 시스템의 상태를 바꾸는 명령어 또는 현재 모드가 user 모드인지 supervisor 모드인지에 따라 작동 방식이 달라지는 CPU 명령어들을 말합니다.

## 가상화 가능한 ISA 의 조건
![virtualization-requirements](https://adriancolyer.files.wordpress.com/2016/02/virtualization-requirements.png "출처: https://blog.acolyer.org/2016/02/19/formal-requirements-for-virtualizable-third-generation-architectures")
어떤 아키텍처가 가상화를 지원하기 위해서는 Guest OS가 시스템 resource를 변경하거나 하는 sensitive 명령어를 수행하려고 할 때 가상머신 모니터가 알아챌 수 있어야 합니다. 그래야 가상머신 모니터가 해당 resource request에 대해 적절히 처리할 수 있기 때문이죠. 그러므로 모든 sensitive 명령어는 trap을 일으켜서 가상머신 모니터가 해당 상황을 적절히 처리할 수 있도록 해야 합니다. 즉 다시 말하면, **모든 sensitive 명령어는 privileged 명령어 이어야 합니다**.

## Intel x86 은 가상화 가능한 ISA일까?
결론적으로는 처음 부분에서 얘기했듯이, x86 아키텍처는 가상화 가능 조건을 충족시키지 못 합니다. 즉 x86 아키텍처에는 **sensitive 명령어이지만 privileged 명령어가 아닌 명령어들**이 있다는 얘기이죠.

이러한 명령어들에 대해서는 [Analysis of the Intel Pentium's ability to support a secure virtual machine monitor](https://dl.acm.org/citation.cfm?id=1251316) 를 읽어보면 알 수 있습니다. 아래에서는 이러한 가상화 가능하지 않은 명령어들중 하나인 [POPF](http://c9x.me/x86/html/file_module_x86_id_250.html) 명령어 에 대해 살펴보려고 합니다.

## POPF 명령어
POPF 명령어는 스택에서 값을 POP 하여 EFLAGS에 넣는 명령어입니다. 그런데 EFLAGS에는 Interrupt Flag (IF) 가 있고 이 값은 CPL 이 0 즉 supervisor mode (ring 0) 일 때에만 값이 설정됩니다. CPL 이 0 이 아닌 경우 값이 설정되지 않고 무시됩니다. (여기서 중요한 점은 user 모드에서 실행되어도 trap이 일어나지 않습니다.) POPF 명령어는 Interrupt Flag를 설정하여 시스템의 상태를 바꿀 수 있고 user 모드인지 supervisor 모드인지에 따라 작동 방식이 달라지므로 sensitive 명령어입니다. 하지만 user 모드에서 실행하여도 trap이 일어나지 않으므로 privileged 명령어는 아니지요. 그러므로 POPF 명령어는 가상화 가능 조건을 만족시키지 못하고 따라서 x86 아키텍처는 가상화 가능 조건을 만족시키지 못한다고 할 수 있습니다.

이 POPF 명령어는 OS가 인터럽트 상태를 바꾸기 위해 사용합니다. 그리고 OS는 supervisor 모드 즉, ring 0에서 수행된다고 가정됩니다. 하지만 이때 하드웨어 가상화 기술이 없는 가상머신의 경우 Guest OS가 ring 0에서 수행되지 않아 문제가 발생되게 됩니다. (보통 ring deprivileging이라고 알려진 문제이지요) 가상머신의 Guest OS 가 POPF를 호출하면 OS이지만 ring 0에서 수행되고 있지 않으므로 IF 가 설정되지 않고 그냥 무시되게 됩니다. 여기서 올바르게 작동하려면 trap이 발생하여 가상머신모니터가 적절히 처리해주어야 합니다.

## References
1. [Formal Requirements for Virtualizable Third Generation Architectures](http://dl.acm.org/citation.cfm?id=361073)
2. [Analysis of the Intel Pentium's ability to support a secure virtual machine monitor](https://dl.acm.org/citation.cfm?id=1251316) 
3. https://blog.acolyer.org/2016/02/19/formal-requirements-for-virtualizable-third-generation-architectures/
4. http://stackoverflow.com/questions/32794361/what-are-non-virtualizable-instructions-in-x86-architecture
5. https://en.wikipedia.org/wiki/X86_virtualization
