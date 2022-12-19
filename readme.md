## A Simplified RISCV-CPU Design
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.2.0/css/all.min.css">

## 目前保证正确运行：
定义正确运行：在能接受的时间内停机并输出正确结果

sim中所有的小样例

大样例中Queens,hanoi,bulgarian能在可接受的时间输出前面部分答案

## CPU架构图


<font face="KAI"></font>
```mermaid

graph TB
    classDef Memory fill:#a9f,stroke:#333,stroke-width:3px;
    
    classDef Process fill:#p3f,stroke:#111,stroke-width:3px;

    classDef Station fill:#d3f,stroke:#111,stroke-width:3px;

    classDef Unit fill:#0099ff,stroke:#111,stroke-width:3px;

    classDef Special fill:#b786d1,stroke:#111,stroke-width:3px;

    classDef Transfer fill:#p3f,stroke:#111,stroke-width:3px;
    subgraph MEMORY
      style MEMORY fill:#00afff
      Mem[fa:fa-memory 128KB Memory]
    end
    subgraph Cache
      style Cache fill:#e7e1ea
      IC(fa:fa-circle-info L1-ICache)
      DC(fa:fa-database L1-Dcache)
    end
    class IC,DC,Mem Memory;
    click Mem,IC,DC "https://www.github.com"
    subgraph Core
      style Core fill:#e7e1ea
      subgraph Register
        style Fetcher fill:#c8e8f7,stroke:#333,stroke-width:3px;
        Reg(fa:fa-abacus Register)
      end
      subgraph Fetcher
        style Fetcher fill:#c8e8f7,stroke:#333,stroke-width:3px;
        PC(fa:fa-arrow-up-9-1 PC reg)
        Inst(fa:fa-circle-info Instruction)
        Prdt(fa:fa-light-bulb Predictor)
      end
      subgraph Dispatcher
        style Dispatcher fill:#c8e8f7,stroke:#333,stroke-width:3px;
        decode(fa:fa-key Decoder)
        Process(fa:fa-microchip Processer)
      end
      class Inst,decode,Process,Prdt Unit
      class PC,Reg Special
      subgraph Processing
        style Processing fill:#c8e8f7,stroke:#333,stroke-width:3px;
        LSB(LoadStoreBuffer)
        RS(ReservationStation)
        ALU(fa:fa-calculator ALU)
        SLU(fa:fa-calculator SLU)
        BUS(fa:fa-bus BUS)
        ROB(fa:fa-code-commit  ReorderBuffer)
        class ALU,SLU,ROB,RS,LSB Station
        class BUS Transfer
      end
    end
    Mem -->|Fetch| IC
    IC  -->|Write?| Mem
    Mem -->|Load| DC
    DC  -->|Write Back| Mem
    IC  -->|Read From| PC
    IC  -->|Instruction| Inst
    Inst--> decode
    decode--> Process
    Process-->|dispatch|RS
    Process-->|dispatch|LSB
    Process-->|Predict|Prdt
    Prdt-->|May Change|PC
    Reg-->|Decoded v_j,v_k|Process
    RS-->|Issue|ALU
    LSB-->|Issue|SLU
    DC-->|Data|SLU
    ALU-->ROB
    SLU-->ROB
    ALU-->|Result|BUS
    SLU-->|Result|BUS
    BUS-->|Update qj,qk|RS
    BUS-->|Update qj,qk|LSB
    ROB-->|Write|Reg
    ROB-->|Train|Prdt
    ROB-->|Write|DC
```