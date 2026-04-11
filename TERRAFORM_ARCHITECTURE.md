# AWS Cloud Architecture & Terraform Strategy

This document outlines the strategy for migrating the Financial Data Pipeline from a local/multi-server environment to AWS using Terraform. It explains how the three core layers of the application are mapped to AWS services and the reasoning behind the Terraform file structure.

## 🗺️ Visual Architecture Diagram

Below is a visual representation of how the components interact in AWS, mapping the data flow and the responsible Terraform files. This reflects a highly available setup (spanning multiple Availability Zones) and proper queue-driven asynchronous processing for the Robo-Advisor.

```text
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                AWS CLOUD (VPC)                                  │
│                                   [main.tf]                                     │
│                                                                                 │
│  ┌────────────────────────┐         ┌────────────────────────────────────────┐  │
│  │   PUBLIC SUBNETS       │         │           PRIVATE SUBNETS              │  │
│  │   (Across 2+ AZs)      │         │           (Across 2+ AZs)              │  │
│  │                        │         │                                        │  │
│  │ ┌───────────────────┐  │         │  ┌──────────────────────────────────┐  │  │
│  │ │ App Load Balancer │──┼────HTTP─┼─►│ Layer 3: Simulator API (ECS)     │  │  │
│  │ │ (ALB)             │  │         │  │ [ecs_fargate.tf]                 │  │  │
│  │ └───────────────────┘  │         │  └─┬────────────────────────────┬───┘  │  │
│  └──────────▲─────────────┘         │    │ write                      │      │  │
│             │                       │    ▼ queue job                  │      │  │
│          Internet                   │  ┌──────────────────────────────────┐  │  │
│           Traffic                   │  │ Amazon SQS (Evaluation Queues)   │  │  │
│                                     │  │ [sqs.tf]                         │  │  │
│  ┌────────────────────────┐         │  └─┬────────────────────────────────┘  │  │
│  │ MANAGED AWS SERVICES   │         │    │ poll                           │  │  │
│  │                        │         │    ▼                                │  │  │
│  │ ┌───────────────────┐  │         │  ┌──────────────────────────────────┐  │  │
│  │ │ Amazon Cognito    │◄─┼──Auth───┼──│ Layer 2: Analysis Engine (EC2)   │  │  │
│  │ │ [cognito.tf]      │  │         │  │ [ec2_gpu.tf]                     │  │  │
│  │ └───────────────────┘  │         │  └─┬───────────────────────────────┬┘  │  │
│  │                        │         │    │ read                    write │   │  │
│  │ ┌───────────────────┐  │         │    ▼                               │   │  │
│  │ │ Amazon SES        │◄─┼─Emails──┼──┌──────────────┐   replicate      │   │  │
│  │ │ [ses.tf]          │  │         │  │ RDS Read     │◄───────┐         │   │  │
│  │ └───────────────────┘  │         │  │ Replica DB   │        │         │   │  │
│  │                        │         │  └──────────────┘        │         │   │  │
│  │ ┌───────────────────┐  │         │                          │         │   │  │
│  │ │ Amazon EventBridge│──┼─Cron────┼─►┌──────────────┐        │         │   │  │
│  │ │ [Scheduled]       │  │         │  │ Layer 1:     │        │         │   │  │
│  │ └───────────────────┘  │         │  │ Data ETL     │        │         │   │  │
│  └────────────────────────┘         │  │ (ECS Task)   │        │         │   │  │
│                                     │  └─┬────────────┘        │         │   │  │
│                                     │    │ write               │         │   │  │
│                                     │    ▼                     │         ▼   │  │
│                                     │  ┌───────────────────────┴──────────┐  │  │
│                                     │  │        Primary Database          │◄─┘   │  │
│                                     │  │      (Amazon RDS Postgres)       │  │  │
│                                     │  │      [database.tf]               │  │  │
│                                     │  └──────────────────────────────────┘  │  │
│                                     └────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────┐
│                          EDGE NETWORK [frontend.tf]                             │
│                                                                                 │
│         ┌──────────────────┐               ┌───────────────────────────┐        │
│ User ──►│ CloudFront (CDN) │ ◄───────────► │ S3 Bucket (React UI)      │        │
│         └──────────────────┘               └───────────────────────────┘        │
└─────────────────────────────────────────────────────────────────────────────────┘

## 🏗️ Architecture Mapping

The system has three distinct tiers combined with external supporting services to drive the Robo-Advisory platform:

### Layer 1: Data Ingestion (financial_data_aggregator)
* **Current State:** Scheduled Python ETL scripts storing data in SQLite.
* **AWS Target:** **Amazon ECS (Fargate) + Amazon EventBridge + Amazon RDS (PostgreSQL)**
* **Reasoning:** ETL jobs are bursty and run on a schedule. By containerizing them and using ECS Fargate, we pay for compute only when pipelines run. Data is written to the **Primary RDS** instance ensuring data durability.

### Layer 2: Analysis Engine (model_regime_comparison)
* **Current State:** Python processes requiring a dedicated LLM-server with a GPU (Ollama/LLaMa2 + Monte Carlo simulations).
* **AWS Target:** **Amazon EC2 (`g4dn.xlarge` or `g5` instances) + Amazon SQS + Amazon RDS Read Replica**
* **Reasoning:** 
  * The EC2 GPU instance acts as an asynchronous **worker node**. It pulls evaluation jobs from an **SQS Queue** submitted by Layer 3. 
  * Because Monte Carlo paths and Markov chain regimes require heavy historical loads, the Engine queries the **RDS Read Replica**, protecting the Primary DB from performance drops.

### Layer 3: Trading Simulator & API
* **Current State:** FastAPI Backend and React (Vite) Frontend.
* **AWS Target:** 
  * **Backend:** **Amazon ECS (Fargate) + Application Load Balancer (ALB)**
  * **Frontend:** **Amazon S3 + Amazon CloudFront (CDN) + Amazon Cognito**
  * **Notifications:** **Amazon SES**
* **Reasoning:** 
  * The frontend uses **Amazon Cognito** to seamlessly create Robo-Advisory user accounts securely.
  * The backend validates Cognito JWT tokens, displays the client dashboard, and pushes rebalance jobs to SQS.
  * **Amazon SES** triggers "trade executed" notification emails straight to the user when a portfolio dynamically shifts.
  * **The Edge Network (CloudFront & S3):** By hosting the static React frontend on S3 and distributing it globally via CloudFront (a CDN), we drastically reduce latency for end-users, no matter their geographic location. It also completely offloads frontend rendering traffic from the backend APIs—meaning the main Fargate clusters and databases are purely focused on high-value business logic and API processing, bypassing standard web-traffic bottlenecks and improving security via Edge firewalls.

---

## 📂 Terraform File Structure & Reasoning

The Infrastructure-as-Code (IaC) is modularized to ensure maintainability, readability, and a clear separation of concerns.

```text
IaC/
├── variables.tf         # Defines inputs (region, passwords, CIDR blocks)
├── main.tf              # Configures the AWS provider and core networking base (VPC, Subnets, IGW)
├── database.tf          # Provisions the central Amazon RDS PostgreSQL database and its security groups
├── ec2_gpu.tf           # Provisions the Layer 2 Analysis Engine (GPU Instance)
├── ecs_fargate.tf       # Sets up Elastic Container Registry (ECR) and the ECS Cluster for Layer 1 & 3
├── frontend.tf          # Configures S3 and CloudFront for the Layer 3 React application
└── outputs.tf           # Defines the outputs printed to the terminal after deployment (URLs, IPs)
```

### Why this structure?
1. **Modularity:** By splitting the resources by logical component (e.g., `database.tf`, `frontend.tf`), it is much easier to find and modify specific parts of the infrastructure without scrolling through a monolithic file.
2. **Security:** Networking (`main.tf`) and variables (`variables.tf`) are isolated. Security groups are defined near the resources that use them to maintain context.
3. **Reusability:** This flat structure is a great starting point. As the infrastructure grows, these individual files can easily be converted into standard Terraform **Modules**.
4. **Visibility:** The `outputs.tf` file explicitly defines what information is useful to the developer once the infrastructure is up (e.g., the URL to access the React dashboard or the database connection string).

---

## 🔒 Security Posture
* **VPC Isolation:** Core processing (Database, GPU EC2, Backend API) happens inside **Private Subnets**. They can access the internet for updates via a NAT Gateway, but cannot be reached directly from the outside.
* **Least Privilege:** Security groups explicitly define port access (e.g., only allowing port `5432` Postgres traffic originating from within the VPC).
* **OAC (Origin Access Control):** The S3 bucket hosting the frontend is locked down so that it can *only* be read by the CloudFront CDN, preventing direct access bypass.
