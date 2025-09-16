export interface Client {
  id: string;
  name: string;
  email: string;
  phone?: string;
  company?: string;
  address?: {
    street: string;
    city: string;
    state: string;
    zipCode: string;
    country: string;
  };
  status: 'active' | 'inactive' | 'suspended';
  createdAt: Date;
  updatedAt: Date;
  metadata?: Record<string, any>;
}

export interface VM {
  id: string;
  name: string;
  clientId: string;
  template: string;
  status: 'creating' | 'running' | 'stopped' | 'suspended' | 'error' | 'destroyed';
  config: {
    cpu: number;
    memory: number; // in MB
    storage: number; // in GB
    network: {
      ip?: string;
      subnet?: string;
      gateway?: string;
    };
  };
  createdAt: Date;
  updatedAt: Date;
  lastAction?: string;
  metadata?: Record<string, any>;
}

export interface Template {
  id: string;
  name: string;
  description: string;
  os: string;
  version: string;
  config: {
    minCpu: number;
    minMemory: number;
    minStorage: number;
  };
  scripts?: string[];
  tags: string[];
  isPublic: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface MonitoringMetrics {
  vmId: string;
  timestamp: Date;
  cpu: {
    usage: number; // percentage
    cores: number;
  };
  memory: {
    used: number; // MB
    total: number; // MB
    usage: number; // percentage
  };
  storage: {
    used: number; // GB
    total: number; // GB
    usage: number; // percentage
  };
  network: {
    bytesIn: number;
    bytesOut: number;
    packetsIn: number;
    packetsOut: number;
  };
}

export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
  pagination?: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
}

export interface VagrantConfig {
  box: string;
  network: {
    type: string;
    ip: string;
  };
  provisioners: Array<{
    type: string;
    script: string;
  }>;
}