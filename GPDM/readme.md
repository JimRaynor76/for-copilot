graph TD
    %% 定义样式
    classDef entry fill:#f9f,stroke:#333,stroke-width:2px;
    classDef core fill:#bbf,stroke:#333,stroke-width:1px;
    classDef util fill:#dfd,stroke:#333,stroke-width:1px;
    classDef ext fill:#eee,stroke:#333,stroke-width:1px,stroke-dasharray: 5 5;

    %% --- 入口脚本 ---
    subgraph Execution_Entry [入口脚本 (你运行的文件)]
        Script[("run_s_demo.py<br>或<br>run_walking_demo.py")]:::entry
        Description[("<b>职责：</b><br>1. 加载/生成数据<br>2. 用 PCA 初始化<br>3. 组装模型和训练器<br>4. 协调画图")]:::ext
    end

    %% --- 外部依赖 ---
    RawData[("原始数据<br>(.pkl 或 生成函数)")]:::ext
    PCA[("sklearn.PCA<br>(初始化猜测)")]:::ext

    %% --- GPDM 核心包 ---
    subgraph GPDM_Package [gpdm/ 文件夹 (核心工具包)]
        direction TB
        
        Trainer["<b>trainer.py</b><br>(GPDMTrainer)"]:::core
        Model["<b>model.py</b><br>(FullGPDM)"]:::core
        Kernels["<b>kernels.py</b>"]:::util
    end

    %% --- 辅助工具 ---
    Plotting["plotting.py<br>(画图工具)"]:::util
    OutputFiles[("输出图片<br>(.png)")]:::ext

    %% --- 流程 ---
    Script -->|1. 读取数据| RawData
    RawData -->|2. 返回观测数据 Y| Script
    Script -->|3. 计算初始隐变量 X0| PCA
    
    Script -->|4. 实例化模型配置| Model
    Script -->|5. 实例化训练器| Trainer
    
    Script -->|6. 调用 fit(Y, X0)| Trainer
    
    %% 内部循环
    Trainer -->|"7. 循环优化 (L-BFGS-B)"| Model
    Model -->|"8. 计算 loss (负对数后验)"| Model
    Model -.->|"9. 调用核函数计算协方差"| Kernels
    Trainer --"10. 返回优化后的参数 (X, beta, alpha)"--> Script

    Script -->|11. 可视化结果| Plotting
    Plotting --> OutputFiles

    %% 链接描述
    Script -.- Description