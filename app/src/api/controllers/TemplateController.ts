import { Request, Response } from 'express';
import { Template, ApiResponse } from '../../types';
import { v4 as uuidv4 } from 'uuid';

class TemplateController {
    private templates: Template[] = [
        {
            id: 'template-ubuntu-22',
            name: 'Ubuntu 22.04 LTS',
            description: 'Standard Ubuntu 22.04 LTS server with basic configuration',
            os: 'Ubuntu',
            version: '22.04',
            config: {
                minCpu: 1,
                minMemory: 512,
                minStorage: 10
            },
            scripts: ['update-system.sh', 'install-docker.sh'],
            tags: ['ubuntu', 'linux', 'lts'],
            isPublic: true,
            createdAt: new Date(),
            updatedAt: new Date()
        },
        {
            id: 'template-centos-8',
            name: 'CentOS 8 Stream',
            description: 'CentOS 8 Stream with enterprise configurations',
            os: 'CentOS',
            version: '8',
            config: {
                minCpu: 1,
                minMemory: 1024,
                minStorage: 15
            },
            scripts: ['update-system.sh', 'setup-firewall.sh'],
            tags: ['centos', 'linux', 'enterprise'],
            isPublic: true,
            createdAt: new Date(),
            updatedAt: new Date()
        }
    ];

    // RF03.1: Create custom template
    public createTemplate = (req: Request, res: Response): void => {
        try {
            const templateData = req.body;
            const newTemplate: Template = {
                id: uuidv4(),
                ...templateData,
                isPublic: templateData.isPublic || false,
                createdAt: new Date(),
                updatedAt: new Date()
            };
            
            this.templates.push(newTemplate);
            
            const response: ApiResponse<Template> = {
                success: true,
                data: newTemplate,
                message: 'Template created successfully'
            };
            res.status(201).json(response);
        } catch (error) {
            const response: ApiResponse = {
                success: false,
                error: 'Failed to create template'
            };
            res.status(500).json(response);
        }
    };

    // Get all templates
    public getTemplates = (req: Request, res: Response): void => {
        try {
            const page = parseInt(req.query.page as string) || 1;
            const limit = parseInt(req.query.limit as string) || 10;
            const os = req.query.os as string;
            const tags = req.query.tags as string;
            const isPublic = req.query.isPublic as string;

            let filteredTemplates = this.templates;

            // Filter by OS
            if (os) {
                filteredTemplates = filteredTemplates.filter(template => 
                    template.os.toLowerCase() === os.toLowerCase());
            }

            // Filter by tags
            if (tags) {
                const tagList = tags.split(',');
                filteredTemplates = filteredTemplates.filter(template =>
                    tagList.some(tag => template.tags.includes(tag.trim())));
            }

            // Filter by public/private
            if (isPublic !== undefined) {
                filteredTemplates = filteredTemplates.filter(template =>
                    template.isPublic === (isPublic === 'true'));
            }

            const startIndex = (page - 1) * limit;
            const endIndex = startIndex + limit;
            const paginatedTemplates = filteredTemplates.slice(startIndex, endIndex);

            const response: ApiResponse<Template[]> = {
                success: true,
                data: paginatedTemplates,
                pagination: {
                    page,
                    limit,
                    total: filteredTemplates.length,
                    totalPages: Math.ceil(filteredTemplates.length / limit)
                }
            };
            res.status(200).json(response);
        } catch (error) {
            const response: ApiResponse = {
                success: false,
                error: 'Failed to retrieve templates'
            };
            res.status(500).json(response);
        }
    };

    // Get specific template
    public getTemplate = (req: Request, res: Response): void => {
        try {
            const templateId = req.params.id;
            const template = this.templates.find(t => t.id === templateId);
            
            if (!template) {
                const response: ApiResponse = {
                    success: false,
                    error: 'Template not found'
                };
                res.status(404).json(response);
                return;
            }
            
            const response: ApiResponse<Template> = {
                success: true,
                data: template
            };
            res.status(200).json(response);
        } catch (error) {
            const response: ApiResponse = {
                success: false,
                error: 'Failed to retrieve template'
            };
            res.status(500).json(response);
        }
    };

    // RF03.2: Edit template
    public updateTemplate = (req: Request, res: Response): void => {
        try {
            const templateId = req.params.id;
            const updateData = req.body;
            const templateIndex = this.templates.findIndex(t => t.id === templateId);
            
            if (templateIndex === -1) {
                const response: ApiResponse = {
                    success: false,
                    error: 'Template not found'
                };
                res.status(404).json(response);
                return;
            }
            
            this.templates[templateIndex] = { 
                ...this.templates[templateIndex], 
                ...updateData, 
                updatedAt: new Date() 
            };
            
            const response: ApiResponse<Template> = {
                success: true,
                data: this.templates[templateIndex],
                message: 'Template updated successfully'
            };
            res.status(200).json(response);
        } catch (error) {
            const response: ApiResponse = {
                success: false,
                error: 'Failed to update template'
            };
            res.status(500).json(response);
        }
    };

    // Delete template
    public deleteTemplate = (req: Request, res: Response): void => {
        try {
            const templateId = req.params.id;
            const templateIndex = this.templates.findIndex(t => t.id === templateId);
            
            if (templateIndex === -1) {
                const response: ApiResponse = {
                    success: false,
                    error: 'Template not found'
                };
                res.status(404).json(response);
                return;
            }
            
            this.templates.splice(templateIndex, 1);
            
            const response: ApiResponse = {
                success: true,
                message: 'Template deleted successfully'
            };
            res.status(200).json(response);
        } catch (error) {
            const response: ApiResponse = {
                success: false,
                error: 'Failed to delete template'
            };
            res.status(500).json(response);
        }
    };

    // RF03.3: Template versions
    public getTemplateVersions = (req: Request, res: Response): void => {
        try {
            const templateId = req.params.id;
            const template = this.templates.find(t => t.id === templateId);
            
            if (!template) {
                const response: ApiResponse = {
                    success: false,
                    error: 'Template not found'
                };
                res.status(404).json(response);
                return;
            }
            
            // Mock version data - in real implementation, this would come from version control
            const versions = [
                {
                    version: '1.0.0',
                    description: 'Initial version',
                    createdAt: template.createdAt,
                    isCurrent: true
                },
                {
                    version: '0.9.0',
                    description: 'Beta version',
                    createdAt: new Date(template.createdAt.getTime() - 24 * 60 * 60 * 1000),
                    isCurrent: false
                }
            ];
            
            const response: ApiResponse = {
                success: true,
                data: versions
            };
            res.status(200).json(response);
        } catch (error) {
            const response: ApiResponse = {
                success: false,
                error: 'Failed to retrieve template versions'
            };
            res.status(500).json(response);
        }
    };

    // RF03.4: Script library
    public getScripts = (req: Request, res: Response): void => {
        try {
            const scripts = [
                {
                    id: 'update-system',
                    name: 'System Update Script',
                    description: 'Updates all system packages',
                    content: '#!/bin/bash\napt-get update && apt-get upgrade -y',
                    category: 'maintenance',
                    tags: ['update', 'system']
                },
                {
                    id: 'install-docker',
                    name: 'Docker Installation',
                    description: 'Installs Docker and Docker Compose',
                    content: '#!/bin/bash\ncurl -fsSL https://get.docker.com -o get-docker.sh\nsh get-docker.sh',
                    category: 'software',
                    tags: ['docker', 'container']
                },
                {
                    id: 'setup-firewall',
                    name: 'Firewall Configuration',
                    description: 'Sets up basic firewall rules',
                    content: '#!/bin/bash\nufw enable\nufw default deny incoming\nufw default allow outgoing\nufw allow ssh',
                    category: 'security',
                    tags: ['firewall', 'security']
                }
            ];
            
            const response: ApiResponse = {
                success: true,
                data: scripts
            };
            res.status(200).json(response);
        } catch (error) {
            const response: ApiResponse = {
                success: false,
                error: 'Failed to retrieve scripts'
            };
            res.status(500).json(response);
        }
    };

    // RF03.5: Network configurations
    public getNetworkConfigs = (req: Request, res: Response): void => {
        try {
            const networkConfigs = [
                {
                    id: 'default-nat',
                    name: 'Default NAT',
                    description: 'Standard NAT configuration with DHCP',
                    type: 'nat',
                    config: {
                        subnet: '192.168.100.0/24',
                        gateway: '192.168.100.1',
                        dhcp: {
                            enabled: true,
                            range: {
                                start: '192.168.100.10',
                                end: '192.168.100.100'
                            }
                        }
                    }
                },
                {
                    id: 'bridged-public',
                    name: 'Bridged Public',
                    description: 'Bridged network for public access',
                    type: 'bridge',
                    config: {
                        bridge: 'br0',
                        dhcp: {
                            enabled: false
                        }
                    }
                },
                {
                    id: 'isolated-private',
                    name: 'Isolated Private',
                    description: 'Isolated network for internal communication',
                    type: 'isolated',
                    config: {
                        subnet: '10.0.0.0/24',
                        gateway: '10.0.0.1',
                        dhcp: {
                            enabled: true,
                            range: {
                                start: '10.0.0.10',
                                end: '10.0.0.100'
                            }
                        }
                    }
                }
            ];
            
            const response: ApiResponse = {
                success: true,
                data: networkConfigs
            };
            res.status(200).json(response);
        } catch (error) {
            const response: ApiResponse = {
                success: false,
                error: 'Failed to retrieve network configurations'
            };
            res.status(500).json(response);
        }
    };

    // RF03.6: Resource profiles
    public getResourceProfiles = (req: Request, res: Response): void => {
        try {
            const profiles = [
                {
                    id: 'small',
                    name: 'Small',
                    description: 'Basic profile for development and testing',
                    config: {
                        cpu: 1,
                        memory: 1024, // 1GB
                        storage: 20,  // 20GB
                        networkBandwidth: 100 // Mbps
                    },
                    pricing: {
                        hourly: 0.05,
                        monthly: 25.00
                    }
                },
                {
                    id: 'medium',
                    name: 'Medium',
                    description: 'Balanced profile for production workloads',
                    config: {
                        cpu: 2,
                        memory: 4096, // 4GB
                        storage: 50,  // 50GB
                        networkBandwidth: 500 // Mbps
                    },
                    pricing: {
                        hourly: 0.15,
                        monthly: 75.00
                    }
                },
                {
                    id: 'large',
                    name: 'Large',
                    description: 'High-performance profile for demanding applications',
                    config: {
                        cpu: 4,
                        memory: 8192, // 8GB
                        storage: 100, // 100GB
                        networkBandwidth: 1000 // Mbps
                    },
                    pricing: {
                        hourly: 0.30,
                        monthly: 150.00
                    }
                },
                {
                    id: 'xlarge',
                    name: 'Extra Large',
                    description: 'Maximum performance for enterprise applications',
                    config: {
                        cpu: 8,
                        memory: 16384, // 16GB
                        storage: 200,  // 200GB
                        networkBandwidth: 2000 // Mbps
                    },
                    pricing: {
                        hourly: 0.60,
                        monthly: 300.00
                    }
                }
            ];
            
            const response: ApiResponse = {
                success: true,
                data: profiles
            };
            res.status(200).json(response);
        } catch (error) {
            const response: ApiResponse = {
                success: false,
                error: 'Failed to retrieve resource profiles'
            };
            res.status(500).json(response);
        }
    };
}

export default TemplateController;