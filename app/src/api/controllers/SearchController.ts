import { Request, Response } from 'express';
import { ApiResponse } from '../../types';

interface SearchResult {
    clients: Array<{
        id: string;
        name: string;
        email: string;
    }>;
    vms: Array<{
        id: string;
        name: string;
        status: string;
    }>;
    templates: Array<{
        id: string;
        name: string;
        category: string;
    }>;
    logs: Array<{
        id: string;
        message: string;
        timestamp: string;
        level: string;
    }>;
}

class SearchController {
    // Mock data - in production this would query actual databases
    private mockClients = [
        { id: 'client-1', name: 'João Silva', email: 'joao@empresa.com' },
        { id: 'client-2', name: 'Maria Santos', email: 'maria@empresa.com' },
        { id: 'client-3', name: 'Pedro Costa', email: 'pedro@empresa.com' }
    ];

    private mockVMs = [
        { id: 'vm-1', name: 'nginx-app-01', status: 'running' },
        { id: 'vm-2', name: 'gitlab-runner-02', status: 'stopped' },
        { id: 'vm-3', name: 'docker-host-01', status: 'running' }
    ];

    private mockTemplates = [
        { id: 'template-1', name: 'Ubuntu Server', category: 'OS Base' },
        { id: 'template-2', name: 'NGINX Web Server', category: 'Web Server' },
        { id: 'template-3', name: 'PostgreSQL Database', category: 'Database' }
    ];

    private mockLogs = [
        {
            id: 'log-1',
            message: 'Failed to connect to upstream server',
            timestamp: '2024-12-19T15:30:25Z',
            level: 'error'
        },
        {
            id: 'log-2',
            message: 'Build pipeline took longer than expected',
            timestamp: '2024-12-19T15:25:15Z',
            level: 'warning'
        }
    ];

    async globalSearch(req: Request, res: Response): Promise<void> {
        try {
            const { q, type } = req.query;

            if (!q || typeof q !== 'string') {
                res.status(400).json({
                    success: false,
                    error: 'Bad Request',
                    message: 'Search query (q) is required'
                } as ApiResponse<null>);
                return;
            }

            const query = q.toLowerCase();
            const searchResults: SearchResult = {
                clients: [],
                vms: [],
                templates: [],
                logs: []
            };

            // Search clients
            if (!type || type === 'clients') {
                searchResults.clients = this.mockClients.filter(client =>
                    client.name.toLowerCase().includes(query) ||
                    client.email.toLowerCase().includes(query)
                );
            }

            // Search VMs
            if (!type || type === 'vms') {
                searchResults.vms = this.mockVMs.filter(vm =>
                    vm.name.toLowerCase().includes(query) ||
                    vm.status.toLowerCase().includes(query)
                );
            }

            // Search templates
            if (!type || type === 'templates') {
                searchResults.templates = this.mockTemplates.filter(template =>
                    template.name.toLowerCase().includes(query) ||
                    template.category.toLowerCase().includes(query)
                );
            }

            // Search logs
            if (!type || type === 'logs') {
                searchResults.logs = this.mockLogs.filter(log =>
                    log.message.toLowerCase().includes(query) ||
                    log.level.toLowerCase().includes(query)
                );
            }

            res.status(200).json({
                success: true,
                data: searchResults,
                message: 'Search completed successfully'
            } as ApiResponse<SearchResult>);
        } catch (error) {
            console.error('Global search error:', error);
            res.status(500).json({
                success: false,
                error: 'Internal server error',
                message: 'Something went wrong during search'
            } as ApiResponse<null>);
        }
    }
}

export default SearchController;