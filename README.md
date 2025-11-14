<p align="center"><a href="https://laravel.com" target="_blank"><img src="https://raw.githubusercontent.com/laravel/art/master/logo-lockup/5%20SVG/2%20CMYK/1%20Full%20Color/laravel-logolockup-cmyk-red.svg" width="400" alt="Laravel Logo"></a></p>

<p align="center">
<a href="https://github.com/laravel/framework/actions"><img src="https://github.com/laravel/framework/workflows/tests/badge.svg" alt="Build Status"></a>
<a href="https://packagist.org/packages/laravel/framework"><img src="https://img.shields.io/packagist/dt/laravel/framework" alt="Total Downloads"></a>
<a href="https://packagist.org/packages/laravel/framework"><img src="https://img.shields.io/packagist/v/laravel/framework" alt="Latest Stable Version"></a>
<a href="https://packagist.org/packages/laravel/framework"><img src="https://img.shields.io/packagist/l/laravel/framework" alt="License"></a>
</p>

# UPI Development Project

This project demonstrates two key implementations:

1. **Workflow Orchestration with Temporal**: A simple workflow that fetches data from an API, transforms it, and saves the result. It includes retry mechanisms and Prometheus metrics for monitoring.
2. **Sharded Data Service**: A service with in-memory sharding for storing user data, exposing Prometheus metrics for shard distribution and request counts.

## Features

### Workflow Orchestration with Temporal
- **Steps**:
  1. Fetch data from an API.
  2. Transform the data.
  3. Save the result (in memory).
- **Retry Mechanism**: Simulates API failure once before succeeding.
- **Metrics**: Prometheus metrics for workflow executions, success/failure rates, and retries.

### Sharded Data Service
- **Endpoint**: `POST /store` to store user data.
- **Sharding**: In-memory sharding based on `userId % N`.
- **Metrics**: Prometheus metrics for request counts per shard and shard distribution.

## Setup Instructions

### Prerequisites
- Docker
- Kubernetes (Minikube or any other cluster)
- Helm
- Prometheus
- Temporal Server

### Installation

1. **Clone the Repository**:
   ```bash
   git clone <repository-url>
   cd upi-dev
   ```

2. **Install Dependencies**:
   ```bash
   composer install
   npm install
   ```

3. **Set Up Environment**:
   Copy `.env.example` to `.env` and configure as needed.

4. **Run Temporal Server**:
   Use the Temporal Docker Compose setup:
   ```bash
   docker-compose -f docker-compose-temporal.yml up
   ```

5. **Deploy to Kubernetes**:
   - Apply the Kubernetes manifests:
     ```bash
     kubectl apply -f kubetest/
     ```
   - Verify the deployment:
     ```bash
     kubectl get pods
     ```

6. **Set Up Prometheus**:
   - Deploy Prometheus using Helm:
     ```bash
     helm install prometheus prometheus-community/prometheus
     ```
   - Access Prometheus:
     ```bash
     kubectl port-forward svc/prometheus-server 9090:80
     ```

## Usage

### Workflow Orchestration
1. Start the Temporal worker:
   ```bash
   php artisan temporal:worker
   ```
2. Trigger the workflow:
   ```bash
   php artisan temporal:trigger-workflow
   ```
3. Monitor metrics in Prometheus.

### Sharded Data Service
1. Start the service:
   ```bash
   php artisan serve
   ```
2. Send a POST request to `/store`:
   ```bash
   curl -X POST -H "Content-Type: application/json" -d '{"userId": 1, "data": "example"}' http://localhost:8000/store
   ```
3. Monitor metrics in Prometheus.

## Metrics
- **Workflow Metrics**:
  - Total executions
  - Success/failure rates
  - Retry counts
- **Sharded Data Service Metrics**:
  - Request counts per shard
  - Shard distribution

## Demo

1. Deploy the application to Kubernetes.
2. Access the services and Prometheus dashboard.
3. Trigger workflows and API requests to observe metrics.

## License
This project is licensed under the MIT License.
