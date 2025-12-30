# 🚀 Application Deployment on AWS EKS with CI/CD and Monitoring

This project demonstrates an **end-to-end containerized application deployment** using **Docker**, **Git Hub**, **Terraform**, **AWS EKS (Kubernetes)**, and **Monitoring with Prometheus & Grafana**

---

## 🧰 Stacks Used

* **Docker** – Containerization
* **AWS EKS** – Kubernetes Cluster
* **kubectl** – Kubernetes CLI
* **eksctl** – EKS Cluster & NodeGroup Management
* **Helm** – Kubernetes Package Manager
* **Prometheus** – Metrics Collection
* **Grafana** – Visualization & Dashboards

---

## 🐳 Step 1: Dockerize the Application

### Build Docker Image Locally

```bash
docker build -t trend-app:v1 .
```

### Test Locally (Optional)

```bash
docker run -p 3000:3000 trend-app:v1
```

---

### Tag Image

```bash
docker tag trend-app:v1 <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/trend-app:v1
```

### Push Image

```bash
docker push <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/trend-app:v1
```

---

## ☸️ Step 3: Deploy Application to AWS EKS

### Create Deployment

```bash
kubectl apply -f deployment.yaml
```

### Create Service (LoadBalancer)

```bash
kubectl apply -f service.yaml
```

### Verify

```bash
kubectl get pods
kubectl get svc
```

Access the application using the **LoadBalancer URL**.

---
## ☸️ Step 4: Jenkins CI/CD
- Install plugins: Docker, Git, Kubernetes, Pipeline.
- Install Docker, Git, kubectl on Jenkins EC2.
- Configure credentials for DockerHub, AWS, GitHub.
- Attach IAM role `ec2_jenkins_role` with `AdministratorAccess`.
- Pipeline stages:
  1. **Build** – compile/test app
  2. **Dockerize** – build & push image to DockerHub
  3. **Deploy** – apply manifests to EKS
  4. **Verify** – check pods/services

---

## 📊 Step 5: Monitoring with Prometheus

### Install Prometheus using Helm

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install prometheus prometheus-community/prometheus \
  -n monitoring --create-namespace \
  --set server.persistentVolume.enabled=false
```

### Verify

```bash
kubectl get pods -n monitoring
kubectl get svc -n monitoring
```

### Access Prometheus

```bash
kubectl port-forward -n monitoring svc/prometheus-server 9090:80
```

Open:

```
http://localhost:9090
```

---

## 📈 Step 6: Install Grafana

### Install Grafana via Helm

```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

helm install grafana grafana/grafana \
  -n monitoring \
  --set persistence.enabled=false \
  --set adminUser=admin \
  --set adminPassword=admin
```

### Verify

```bash
kubectl get pods -n monitoring
kubectl get svc -n monitoring
```

### Access Grafana

```bash
kubectl port-forward -n monitoring svc/grafana 3000:80
```

Open:

```
http://localhost:3000
```

---

## 🔗 Step 7: Connect Prometheus to Grafana

### Add Data Source in Grafana

* **Type**: Prometheus
* **URL**:

```
http://prometheus-server.monitoring.svc.cluster.local
```

* Click **Save & Test**

---


## 🔍 Verification Commands

```bash
kubectl get nodes
kubectl get svc
```

---
