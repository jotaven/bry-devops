# 🚀 Implantação de Serviços de Alta Disponibilidade na AWS

Este repositório contém a Arquitetura de Referência e o código completo para a implantação automatizada de serviços de alta disponibilidade na AWS, utilizando **EKS (Kubernetes)** e a metodologia **IaC (Infrastructure as Code)**.

A solução implementa todos os requisitos mínimos e avança nos componentes bónus

## 1. 🗺️ Arquitetura e Fluxo da Solução

A arquitetura é projetada para o Zero Trust (segurança rigorosa) e para a recuperação automática.

### 1.1. Fluxo de Tráfego do Usuário (Entrada)

Esta é a jornada de uma requisição para a aplicação (`whoami`):

1. **Usuário** acessa `https://bry.jotinha.dev`.
2. **AWS Route 53** (gerenciado automaticamente pelo **ExternalDNS**) aponta para o NLB.
3. **AWS Network Load Balancer (NLB)** (Criado pelo Nginx Ingress) encaminha o tráfego.
4. **Nginx Ingress Controller** (Rodando no EKS) **termina o SSL** (usando o certificado do **Cert-Manager**) e roteia a requisição para o Service (`whoami-service`).
5. **Aplicação `whoami`** (Rodando em Nodes `t3.large` privados) responde.

### 1.2. Fluxo de Gerenciamento (CI/CD Automatizado)

O gerenciamento é totalmente desacoplado e automatizado via **GitHub Actions** (OIDC):

- **Trilha de Infraestrutura:** Mudanças na pasta `/terraform` disparam o pipeline de Infra. O robô veste o **IAM Role de Administrador (OIDC)**, executa `terraform plan`, e depois `terraform apply`.
- **Trilha da Aplicação:** Mudanças no código/manifestos disparam um pipeline (não implementado neste commit, mas planejado) que constrói o Docker, faz `push` para o ECR e atualiza o Helm no EKS.

---

## 2. 🛡️ Pilares da Alta Disponibilidade (HA) e Segurança

Os seguintes componentes foram implementados e configurados para garantir a resiliência e a segurança avançada:

| Pilar | Ferramenta | Justificativa |
| --- | --- | --- |
| **Infraestrutura HA** | **AWS EKS + Terraform** | O Control Plane é gerenciado pela AWS. Os Worker Nodes (`t3.large`) são distribuídos em Múltiplas Zonas de Disponibilidade (Multi-AZ) para resiliência a falhas de datacenter. |
| **Isolamento de Rede** | **AWS VPC + Subnets Privadas** | Os Nodes que rodam a aplicação estão em Subnets Privadas e só podem ser alcançados através do NLB. |
| **Zero Trust** | **Calico Network Policies** | Aplicámos a regra `default-deny` no namespace principal, bloqueando todo o tráfego interno. Isso impede que um pod invadido se mova lateralmente pelo cluster. |
| **Escalabilidade** | **Kubernetes HPA** | Configurámos o `whoami-hpa` para dimensionar de 2 para 10 réplicas automaticamente com base na utilização da CPU (`averageUtilization: 80%`). |
| **Escalabilidade (Bónus)** | **KEDA (SQS)** | Configurámos o `ScaledObject` para o `whoami-deployment` ligar-se à Fila SQS (`jotinha-whoami-jobs`) e escalar de **0 para N** (Scale-to-Zero), otimizando os custos em momentos de inatividade. |
| **Gerenciamento de Segredos** | **HashiCorp Vault + Injector** | Instalamos o Vault em modo `dev` e configurámos o Ingress. O Vault Agent Injector injeta os segredos como um *sidecar* diretamente no pod, evitando a exposição de senhas em Secrets do Kubernetes. |

---

### **2.1. 💾 Os Componentes de Infraestrutura como Código (IaC)**

A arquitetura é construída com **separação total** de responsabilidades para evitar "Desvios" (Drift) e garantir a rastreabilidade.**ComponenteFerramenta/LocalizaçãoPropósito ArquiteturalAcesso Web**AWS NLB (Layer 4)Fornece um único ponto de entrada **elástico** e de baixo custo para o cluster.**Roteamento SSL**Nginx Ingress + Cert-ManagerO Nginx atua como **Recepcionista** (roteador Layer 7) e termina o SSL usando certificados Let's Encrypt.**Persistência de Aplicação**EBS Volumes (`gp2`/`gp3`)Volumes de disco rápidos anexados aos Nodes (`t3.large`) para o uso do Elasticsearch.**Provedor OIDC**AWS IAMCria a relação de **confiança criptográfica** para o CI/CD (GitHub) e para os Pods (IRSA).**Worker Nodes**AWS EC2 (`t3.large`)Fornece os recursos de cômputo (8GB RAM) necessários para rodar cargas pesadas como a pilha de Logs.

### **2.2. 🔒 A Tríade da Segurança e da Confiança**

Estes componentes são os guardiões da estabilidade e do acesso.

**A. O "Policial de Tráfego" (Calico)**

• **O que é:** O CNI (Container Network Interface) e motor de Network Policy. O Calico é a ferramenta que nos permitiu implementar a filosofia **Zero Trust** dentro do cluster.
• **Implementação:** Instalado via Helm. Por defeito, o Calico **bloqueia toda a comunicação pod-a-pod** entre Namespaces.
• **Regra Crítica:** Foi necessário adicionar a regra `allow-ingress-nginx.yaml` para explicitamente permitir que o **Recepcionista** (`ingress-nginx` namespace) falasse com os **Trabalhadores** (`default` namespace). Sem esta regra, o Cert-Manager não conseguiria completar a prova SSL, e a aplicação seria inacessível.

**B. O "Cofre" e o "Cadeado" (S3 & DynamoDB)**

• **AWS S3 Bucket (`jotinha-dev-terraform-state-prod...`)**
    ◦ **Propósito:** Serve como **Cofre** para o arquivo de estado (`terraform.tfstate`). Isto é crucial para permitir o CI/CD (GitHub Actions) e a colaboração de equipa, garantindo que a "memória" da infraestrutura não seja perdida ou fique no computador local de um engenheiro.
    ◦ **Segurança:** O Versionamento está ativo, permitindo *rollbacks* a versões antigas do estado em caso de erro.
• **AWS DynamoDB Table (`jotinha-dev-terraform-lock`)**
    ◦ **Propósito:** Serve como **Cadeado** (State Locking). A tabela impede que dois processos (ex: um engenheiro e o Robô do CI/CD) executem o `terraform apply` ao mesmo tempo, prevenindo a **corrupção do estado** do projeto.

## 3. 💾 Estrutura do Projeto

O projeto segue a separação de responsabilidades (SoC):

```.
├── terraform/                # CÓDIGO DA INFRAESTRUTURA (AWS)
│   ├── main.tf               # Configura o backend S3, EKS e IAM
│   └── modules/
│       ├── vpc/              # Módulo isolado de rede (VPC, Subnets, NATs, EPs)
│       └── iam_roles/        # Módulo que cria todos os IAM Roles (IRSA, CI/CD)
├── k8s/                      # MANIFESTOS DO KUBERNETES (YAMLS)
│   ├── app/                  # Aplicação (Deployment, Service, Ingress, HPA)
│   ├── calico/               # Regras de Network Policy (Defesas internas)
│   ├── monitoring/           # Configurações do Prometheus/Grafana
│   └── logging/              # Configurações do Elasticsearch/Kibana
└── .github/
    └── workflows/infra.yml   # O CI/CD (GitHub Actions)`
```
---

## 4. 📈 Observabilidade Implementada (Ponto Bónus)

A pilha de Observabilidade foi projetada para cobrir Logs e Métricas:

| Componente | Função | Localização |
| --- | --- | --- |
| **Prometheus** | **Métricas e Alerting** (O "Fiscal") | Coleta o uso de CPU, memória, latência do Nginx e a saúde geral do K8s. |
| **Grafana** | **Visualização** (O "Painel de Gráficos") | Apresenta os dashboards de forma gráfica. |
| **Elasticsearch** | **Armazenamento de Logs** (O "Arquivo Central") | Banco de dados centralizado que armazena os logs de todos os pods. |
| **Filebeat** | **Coleta de Logs** (O "Coletor") | Rodando em cada Node (`DaemonSet`), coleta logs e envia-os ao Elasticsearch. |

Para aceder ao Grafana ou Kibana (eles são internos ao cluster), você deve usar o `kubectl port-forward` após a implantação.

---

## 5. 🛠️ Primeiros Passos e Validação (Quick Start)

Assumindo que você tem as credenciais da AWS configuradas e os domínios `jotinha.dev` delegados ao Route 53.

### 5.1. Implantação da Infraestrutura (Terraform)

1. **Crie os Backends:** S3 Bucket (`jotinha-dev-terraform-state-prod-nova-conta`) e DynamoDB Table (`jotinha-dev-terraform-lock`).
2. **Inicialize:** Navegue até a pasta `/terraform` e execute:
    
    `terraform init`
    
3. **Construa:**
    
    `terraform apply`
    

### 5.2. Implantação dos Serviços (Kubernetes)

1. **Conecte-se ao Cluster:**
    
    `aws eks update-kubeconfig --region us-east-1 --name jotinha-eks-cluster`
    
2. **Instale os Módulos (Segurança e Aplicação):**
    
    `helm install [o nome] [o chart]...
    kubectl apply -f k8s/calico/
    kubectl apply -f k8s/app/`
    

### 5.3. Validação de Ponta a Ponta

- **DNS & SSL:** O teste final é o acesso externo, que confirma que todo o pipeline funcionou
    
    `https://bry.jotinha.dev`
    
- **Escalabilidade (HPA):** Verifique se o HPA está a funcionar e a vigiar a CPU
    
    `kubectl get hpa -n default`