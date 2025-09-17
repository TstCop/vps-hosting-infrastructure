# TODOS_BACKEND.md

## 📋 APIs Necessárias para o Frontend VPS Hosting Infrastructure

Este documento lista todas as APIs que precisam ser implementadas no backend para suportar completamente o frontend desenvolvido.

---

## 🏠 **Dashboard APIs**

### `GET /api/monitoring/dashboard`
**Descrição**: Dados gerais do dashboard
**Resposta**:
```json
{
  "success": true,
  "data": {
    "totalVMs": 12,
    "activeVMs": 10,
    "stoppedVMs": 2,
    "totalClients": 8,
    "activeClients": 6,
    "resourceUsage": {
      "cpu": { "used": 45.2, "total": 100, "unit": "percentage" },
      "memory": { "used": 87.2, "total": 512, "unit": "GB" },
      "storage": { "used": 1.2, "total": 10, "unit": "TB" }
    },
    "recentActivity": [
      {
        "id": "1",
        "type": "vm_created",
        "message": "VM nginx-app-01 criada",
        "timestamp": "2024-12-19T15:30:00Z"
      }
    ]
  }
}
```

---

## 👥 **Client APIs**

### `GET /api/clients`
**Descrição**: Lista todos os clientes
**Query Params**: `page`, `limit`, `search`, `status`
**Resposta**:
```json
{
  "success": true,
  "data": [
    {
      "id": "client-1",
      "name": "João Silva",
      "email": "joao@empresa.com",
      "company": "Empresa A",
      "phone": "+55 11 99999-9999",
      "status": "active",
      "vmsCount": 3,
      "createdAt": "2024-01-15T10:00:00Z",
      "updatedAt": "2024-12-19T15:30:00Z",
      "address": {
        "street": "Rua das Flores, 123",
        "city": "São Paulo",
        "state": "SP",
        "zipCode": "01234-567",
        "country": "Brasil"
      }
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 50,
    "totalPages": 3
  }
}
```

### `GET /api/clients/:id`
**Descrição**: Detalhes de um cliente específico
**Resposta**:
```json
{
  "success": true,
  "data": {
    "id": "client-1",
    "name": "João Silva",
    "email": "joao@empresa.com",
    "company": "Empresa A",
    "phone": "+55 11 99999-9999",
    "status": "active",
    "vmsCount": 3,
    "createdAt": "2024-01-15T10:00:00Z",
    "updatedAt": "2024-12-19T15:30:00Z",
    "vms": [
      {
        "id": "vm-1",
        "name": "nginx-app-01",
        "status": "running",
        "template": "Ubuntu 22.04"
      }
    ]
  }
}
```

### `POST /api/clients`
**Descrição**: Criar novo cliente
**Request Body**:
```json
{
  "name": "João Silva",
  "email": "joao@empresa.com",
  "company": "Empresa A",
  "phone": "+55 11 99999-9999",
  "address": {
    "street": "Rua das Flores, 123",
    "city": "São Paulo",
    "state": "SP",
    "zipCode": "01234-567",
    "country": "Brasil"
  }
}
```

### `PUT /api/clients/:id`
**Descrição**: Atualizar cliente existente

### `DELETE /api/clients/:id`
**Descrição**: Excluir cliente

### `GET /api/clients/:id/vms`
**Descrição**: VMs de um cliente específico

---

## 💻 **Virtual Machines APIs**

### `GET /api/vms`
**Descrição**: Lista todas as VMs
**Query Params**: `page`, `limit`, `search`, `status`, `clientId`, `template`
**Resposta**:
```json
{
  "success": true,
  "data": [
    {
      "id": "vm-1",
      "name": "nginx-app-01",
      "clientId": "client-1",
      "clientName": "Empresa A",
      "status": "running",
      "template": "Ubuntu 22.04",
      "config": {
        "cpu": 2,
        "memory": 4096,
        "storage": 40,
        "network": {
          "ip": "192.168.1.100",
          "subnet": "192.168.1.0/24",
          "gateway": "192.168.1.1"
        }
      },
      "uptime": "5d 2h 30m",
      "createdAt": "2024-12-14T10:00:00Z",
      "updatedAt": "2024-12-19T15:30:00Z",
      "lastAction": "start"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 45,
    "totalPages": 3
  }
}
```

### `GET /api/vms/:id`
**Descrição**: Detalhes de uma VM específica
**Resposta**:
```json
{
  "success": true,
  "data": {
    "id": "vm-1",
    "name": "nginx-app-01",
    "clientId": "client-1",
    "clientName": "Empresa A",
    "status": "running",
    "template": "Ubuntu 22.04",
    "config": {
      "cpu": 2,
      "memory": 4096,
      "storage": 40,
      "network": {
        "ip": "192.168.1.100",
        "subnet": "192.168.1.0/24",
        "gateway": "192.168.1.1"
      }
    },
    "metrics": {
      "cpuUsage": 15.2,
      "memoryUsage": 45.8,
      "diskUsage": 30.1,
      "networkIn": 125.4,
      "networkOut": 89.7
    },
    "uptime": "5d 2h 30m",
    "createdAt": "2024-12-14T10:00:00Z",
    "updatedAt": "2024-12-19T15:30:00Z"
  }
}
```

### `POST /api/vms`
**Descrição**: Criar nova VM
**Request Body**:
```json
{
  "name": "nginx-app-01",
  "clientId": "client-1",
  "templateId": "template-1",
  "config": {
    "cpu": 2,
    "memory": 4096,
    "storage": 40,
    "network": "default"
  }
}
```

### `PUT /api/vms/:id`
**Descrição**: Atualizar configurações da VM

### `DELETE /api/vms/:id`
**Descrição**: Excluir VM

### `POST /api/vms/:id/start`
**Descrição**: Iniciar VM

### `POST /api/vms/:id/stop`
**Descrição**: Parar VM

### `POST /api/vms/:id/restart`
**Descrição**: Reiniciar VM

### `GET /api/vms/:id/metrics`
**Descrição**: Métricas em tempo real da VM
**Query Params**: `timeRange` (1h, 6h, 24h, 7d), `interval` (1m, 5m, 1h)
**Resposta**:
```json
{
  "success": true,
  "data": {
    "vmId": "vm-1",
    "timeRange": "1h",
    "interval": "5m",
    "metrics": [
      {
        "timestamp": "2024-12-19T15:30:00Z",
        "cpu": 15.2,
        "memory": 45.8,
        "disk": 30.1,
        "networkIn": 125.4,
        "networkOut": 89.7
      }
    ]
  }
}
```

---

## 📋 **Templates APIs**

### `GET /api/templates`
**Descrição**: Lista todos os templates
**Query Params**: `category`, `search`, `popular`
**Resposta**:
```json
{
  "success": true,
  "data": [
    {
      "id": "template-1",
      "name": "Ubuntu Server",
      "category": "OS Base",
      "description": "Ubuntu 22.04 LTS com configurações otimizadas",
      "os": "Ubuntu",
      "version": "22.04 LTS",
      "popular": true,
      "config": {
        "cpu": 2,
        "memory": 4096,
        "storage": 40
      },
      "scripts": [
        {
          "name": "setup.sh",
          "description": "Configuração inicial do sistema"
        }
      ],
      "createdAt": "2024-01-01T00:00:00Z"
    }
  ]
}
```

### `GET /api/templates/:id`
**Descrição**: Detalhes de um template específico

### `POST /api/templates`
**Descrição**: Criar novo template

### `PUT /api/templates/:id`
**Descrição**: Atualizar template

### `DELETE /api/templates/:id`
**Descrição**: Excluir template

### `GET /api/templates/categories`
**Descrição**: Lista de categorias disponíveis
**Resposta**:
```json
{
  "success": true,
  "data": [
    "OS Base",
    "Web Server",
    "Database",
    "DevOps",
    "Development"
  ]
}
```

### `POST /api/templates/:id/deploy`
**Descrição**: Deploy de um template como nova VM
**Request Body**:
```json
{
  "vmName": "nginx-app-01",
  "clientId": "client-1",
  "config": {
    "cpu": 2,
    "memory": 4096,
    "storage": 40,
    "network": "default"
  }
}
```

---

## 📊 **Monitoring APIs**

### `GET /api/monitoring/metrics`
**Descrição**: Métricas globais do sistema
**Query Params**: `timeRange`, `interval`
**Resposta**:
```json
{
  "success": true,
  "data": {
    "system": {
      "cpuUsage": 65.4,
      "memoryUsage": 78.2,
      "diskUsage": 45.8,
      "networkIn": 125.4,
      "networkOut": 89.7
    },
    "vms": [
      {
        "id": "vm-1",
        "name": "nginx-app-01",
        "status": "running",
        "cpuUsage": 15.2,
        "memoryUsage": 45.8,
        "diskUsage": 30.1
      }
    ]
  }
}
```

### `GET /api/monitoring/alerts`
**Descrição**: Lista de alertas
**Query Params**: `severity`, `status`, `page`, `limit`
**Resposta**:
```json
{
  "success": true,
  "data": [
    {
      "id": "alert-1",
      "type": "error",
      "title": "VM nginx-app-01 Down",
      "message": "VM parou de responder há 5 minutos",
      "severity": "high",
      "status": "active",
      "source": "vm-1",
      "timestamp": "2024-12-19T15:30:00Z",
      "createdAt": "2024-12-19T15:30:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 5,
    "totalPages": 1
  }
}
```

### `PUT /api/monitoring/alerts/:id`
**Descrição**: Atualizar status do alerta (ack, resolved)

### `GET /api/monitoring/performance-reports`
**Descrição**: Relatórios de performance
**Query Params**: `type` (summary, detailed), `period` (last_7_days, last_30_days)

---

## 📝 **Logs APIs**

### `GET /api/logs`
**Descrição**: Sistema de logs com filtros avançados
**Query Params**: `level`, `service`, `vm`, `component`, `search`, `startDate`, `endDate`, `page`, `limit`
**Resposta**:
```json
{
  "success": true,
  "data": [
    {
      "id": "log-1",
      "timestamp": "2024-12-19T15:30:25Z",
      "level": "error",
      "service": "nginx",
      "vm": "nginx-app-01",
      "component": "web-server",
      "message": "Failed to connect to upstream server",
      "details": "Connection timeout after 30 seconds",
      "user": "admin",
      "ip": "192.168.1.100",
      "metadata": {
        "requestId": "req-123",
        "userAgent": "Mozilla/5.0..."
      }
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 50,
    "total": 1250,
    "totalPages": 25
  }
}
```

### `GET /api/logs/:id`
**Descrição**: Detalhes de um log específico

### `GET /api/logs/export`
**Descrição**: Exportar logs em CSV
**Query Params**: mesmos filtros de GET /api/logs
**Resposta**: Arquivo CSV

### `GET /api/logs/stats`
**Descrição**: Estatísticas dos logs
**Resposta**:
```json
{
  "success": true,
  "data": {
    "total": 1250,
    "byLevel": {
      "error": 45,
      "warning": 123,
      "info": 890,
      "debug": 192
    },
    "byService": {
      "nginx": 450,
      "gitlab": 300,
      "docker": 200,
      "kvm": 300
    }
  }
}
```

---

## 🔧 **Configuration APIs**

### `GET /api/configs/scripts`
**Descrição**: Biblioteca de scripts
**Resposta**:
```json
{
  "success": true,
  "data": [
    {
      "id": "script-1",
      "name": "Setup NGINX",
      "description": "Instala e configura NGINX",
      "content": "#!/bin/bash\napt-get update...",
      "category": "web-server",
      "language": "bash"
    }
  ]
}
```

### `GET /api/configs/network-profiles`
**Descrição**: Perfis de rede disponíveis
**Resposta**:
```json
{
  "success": true,
  "data": [
    {
      "id": "nat-default",
      "name": "Default NAT",
      "description": "Configuração NAT padrão",
      "type": "nat",
      "config": {
        "subnet": "192.168.100.0/24",
        "gateway": "192.168.100.1",
        "dhcp": {
          "enabled": true,
          "range": {
            "start": "192.168.100.10",
            "end": "192.168.100.100"
          }
        }
      }
    }
  ]
}
```

### `GET /api/configs/resource-profiles`
**Descrição**: Perfis de recursos predefinidos
**Resposta**:
```json
{
  "success": true,
  "data": [
    {
      "id": "small",
      "name": "Small",
      "description": "Para desenvolvimento e testes",
      "config": {
        "cpu": 1,
        "memory": 1024,
        "storage": 20
      },
      "pricing": {
        "hourly": 0.05,
        "monthly": 25.00
      }
    }
  ]
}
```

---

## 🔐 **Authentication APIs**

### `POST /api/auth/login`
**Descrição**: Login do usuário
**Request Body**:
```json
{
  "email": "admin@exemplo.com",
  "password": "senha123"
}
```
**Resposta**:
```json
{
  "success": true,
  "data": {
    "token": "jwt-token-here",
    "user": {
      "id": "user-1",
      "name": "Admin",
      "email": "admin@exemplo.com",
      "role": "admin"
    }
  }
}
```

### `POST /api/auth/logout`
**Descrição**: Logout do usuário

### `GET /api/auth/me`
**Descrição**: Dados do usuário logado

### `POST /api/auth/refresh`
**Descrição**: Refresh do token JWT

---

## 📈 **Statistics APIs**

### `GET /api/stats/overview`
**Descrição**: Estatísticas gerais
**Resposta**:
```json
{
  "success": true,
  "data": {
    "clients": {
      "total": 50,
      "active": 45,
      "new_this_month": 5
    },
    "vms": {
      "total": 150,
      "running": 142,
      "stopped": 8,
      "created_this_month": 20
    },
    "resources": {
      "cpu_utilization": 65.4,
      "memory_utilization": 78.2,
      "storage_utilization": 45.8
    }
  }
}
```

---

## 🔍 **Search APIs**

### `GET /api/search`
**Descrição**: Busca global
**Query Params**: `q` (query), `type` (clients, vms, templates, logs)
**Resposta**:
```json
{
  "success": true,
  "data": {
    "clients": [
      {
        "id": "client-1",
        "name": "João Silva",
        "email": "joao@empresa.com"
      }
    ],
    "vms": [
      {
        "id": "vm-1",
        "name": "nginx-app-01",
        "status": "running"
      }
    ],
    "templates": [],
    "logs": []
  }
}
```

---

## 📁 **File Management APIs**

### `POST /api/files/upload`
**Descrição**: Upload de arquivos (scripts, configs)
**Content-Type**: multipart/form-data

### `GET /api/files/:id`
**Descrição**: Download de arquivo

### `DELETE /api/files/:id`
**Descrição**: Excluir arquivo

---

## 🔧 **System APIs**

### `GET /api/system/health`
**Descrição**: Health check do sistema
**Resposta**:
```json
{
  "success": true,
  "data": {
    "status": "healthy",
    "timestamp": "2024-12-19T15:30:00Z",
    "services": {
      "database": "healthy",
      "vagrant": "healthy",
      "kvm": "healthy"
    }
  }
}
```

### `GET /api/system/info`
**Descrição**: Informações do sistema

---

## 🔄 **Backup APIs**

### `GET /api/backups`
**Descrição**: Lista de backups

### `POST /api/backups`
**Descrição**: Criar backup

### `POST /api/backups/:id/restore`
**Descrição**: Restaurar backup

---

## 📋 **Resumo de Implementação**

### **Prioridade Alta** 🔥
1. **Dashboard APIs** - Essencial para a página inicial
2. **VM Management APIs** - Core do sistema
3. **Client APIs** - Gerenciamento de clientes
4. **Authentication APIs** - Segurança básica

### **Prioridade Média** 📊
1. **Monitoring APIs** - Métricas e alertas
2. **Templates APIs** - Marketplace de templates
3. **Logs APIs** - Sistema de logging

### **Prioridade Baixa** 🔧
1. **Configuration APIs** - Configurações avançadas
2. **File Management APIs** - Upload/download
3. **Backup APIs** - Funcionalidades extras

---

## 🛠 **Especificações Técnicas**

### **Padrão de Resposta**
Todas as APIs devem seguir o padrão:
```json
{
  "success": boolean,
  "data": any,
  "error": string,
  "message": string,
  "pagination": {
    "page": number,
    "limit": number,
    "total": number,
    "totalPages": number
  }
}
```

### **Códigos de Status HTTP**
- `200` - Sucesso
- `201` - Criado
- `400` - Bad Request
- `401` - Não autorizado
- `403` - Proibido
- `404` - Não encontrado
- `500` - Erro interno

### **Headers Obrigatórios**
- `Authorization: Bearer <token>` (exceto login)
- `Content-Type: application/json`

### **Rate Limiting**
- 100 requisições por minuto por IP
- 1000 requisições por hora por usuário autenticado

---

## 📝 **Observações Finais**

1. **Todas as APIs devem ter autenticação JWT**
2. **Implementar paginação em listagens**
3. **Logs de auditoria para ações críticas**
4. **Validação rigorosa de entrada**
5. **Rate limiting para evitar abuso**
6. **Documentação Swagger/OpenAPI**
7. **Testes unitários e de integração**
8. **Monitoramento de performance**

Este documento serve como especificação completa para o desenvolvimento do backend que suportará 100% das funcionalidades implementadas no frontend. 🚀
