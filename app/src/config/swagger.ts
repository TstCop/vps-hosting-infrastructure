import swaggerJsdoc from 'swagger-jsdoc';
import swaggerUi from 'swagger-ui-express';

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'VPS Hosting Infrastructure API',
      version: '1.0.0',
      description: 'API para gerenciamento de infraestrutura de VPS com Vagrant e KVM',
      contact: {
        name: 'VPS Team',
        email: 'support@vpshosting.com'
      },
      license: {
        name: 'MIT',
        url: 'https://opensource.org/licenses/MIT'
      }
    },
    tags: [
      {
        name: 'Health',
        description: 'API health check endpoints'
      },
      {
        name: 'Clients',
        description: 'Client management operations'
      },
      {
        name: 'Virtual Machines',
        description: 'VM management and operations'
      },
      {
        name: 'Templates',
        description: 'VM template management'
      },
      {
        name: 'Monitoring',
        description: 'System monitoring and metrics'
      },
      {
        name: 'Configuration',
        description: 'System configuration management'
      }
    ],
    servers: [
      {
        url: 'http://localhost:4444',
        description: 'Development server'
      }
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT'
        }
      },
      schemas: {
        Client: {
          type: 'object',
          required: ['id', 'name', 'email', 'status', 'createdAt', 'updatedAt'],
          properties: {
            id: {
              type: 'string',
              description: 'Unique client identifier'
            },
            name: {
              type: 'string',
              description: 'Client full name'
            },
            email: {
              type: 'string',
              format: 'email',
              description: 'Client email address'
            },
            company: {
              type: 'string',
              description: 'Client company name'
            },
            phone: {
              type: 'string',
              description: 'Client phone number'
            },
            status: {
              type: 'string',
              enum: ['active', 'inactive'],
              description: 'Client status'
            },
            createdAt: {
              type: 'string',
              format: 'date-time',
              description: 'Client creation timestamp'
            },
            updatedAt: {
              type: 'string',
              format: 'date-time',
              description: 'Client last update timestamp'
            }
          }
        },
        VM: {
          type: 'object',
          required: ['id', 'name', 'status', 'clientId', 'templateId'],
          properties: {
            id: {
              type: 'string',
              description: 'Unique VM identifier'
            },
            name: {
              type: 'string',
              description: 'VM name'
            },
            status: {
              type: 'string',
              enum: ['running', 'stopped', 'pending', 'error'],
              description: 'VM status'
            },
            clientId: {
              type: 'string',
              description: 'Associated client ID'
            },
            templateId: {
              type: 'string',
              description: 'Template used for VM creation'
            },
            ipAddress: {
              type: 'string',
              description: 'VM IP address'
            },
            specs: {
              type: 'object',
              properties: {
                cpu: {
                  type: 'integer',
                  description: 'CPU cores'
                },
                memory: {
                  type: 'integer',
                  description: 'Memory in MB'
                },
                disk: {
                  type: 'integer',
                  description: 'Disk space in GB'
                }
              }
            },
            createdAt: {
              type: 'string',
              format: 'date-time'
            },
            updatedAt: {
              type: 'string',
              format: 'date-time'
            }
          }
        },
        Template: {
          type: 'object',
          required: ['id', 'name', 'os', 'specs'],
          properties: {
            id: {
              type: 'string',
              description: 'Unique template identifier'
            },
            name: {
              type: 'string',
              description: 'Template name'
            },
            os: {
              type: 'string',
              description: 'Operating system'
            },
            specs: {
              type: 'object',
              properties: {
                cpu: {
                  type: 'integer'
                },
                memory: {
                  type: 'integer'
                },
                disk: {
                  type: 'integer'
                }
              }
            },
            createdAt: {
              type: 'string',
              format: 'date-time'
            }
          }
        },
        ApiResponse: {
          type: 'object',
          properties: {
            success: {
              type: 'boolean',
              description: 'Indicates if the operation was successful'
            },
            data: {
              description: 'Response data (varies by endpoint)'
            },
            message: {
              type: 'string',
              description: 'Success message'
            },
            error: {
              type: 'string',
              description: 'Error message (when success is false)'
            }
          }
        }
      }
    },
    security: [
      {
        bearerAuth: []
      }
    ]
  },
  apis: ['./src/api/routes/*.ts', './src/api/controllers/*.ts', './src/api/app.ts'], // Caminhos para os arquivos com anotações Swagger
};

const specs = swaggerJsdoc(options);

export { specs, swaggerUi };
