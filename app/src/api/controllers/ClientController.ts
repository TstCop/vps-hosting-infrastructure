import { Request, Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { ApiResponse, Client } from '../../types';

class ClientController {
    private clients: Client[] = [];

    /**
     * @swagger
     * /api/clients:
     *   post:
     *     summary: Create a new client
     *     tags: [Clients]
     *     security:
     *       - bearerAuth: []
     *     requestBody:
     *       required: true
     *       content:
     *         application/json:
     *           schema:
     *             type: object
     *             required:
     *               - name
     *               - email
     *             properties:
     *               name:
     *                 type: string
     *                 description: Client name
     *               email:
     *                 type: string
     *                 format: email
     *                 description: Client email
     *               company:
     *                 type: string
     *                 description: Client company
     *               phone:
     *                 type: string
     *                 description: Client phone number
     *     responses:
     *       201:
     *         description: Client created successfully
     *         content:
     *           application/json:
     *             schema:
     *               type: object
     *               properties:
     *                 success:
     *                   type: boolean
     *                 data:
     *                   $ref: '#/components/schemas/Client'
     *                 message:
     *                   type: string
     *       500:
     *         description: Internal server error
     */
    // RF01.1: Create new client
    public createClient = (req: Request, res: Response): void => {
        try {
            const clientData = req.body;
            const newClient: Client = {
                id: uuidv4(),
                ...clientData,
                status: 'active',
                createdAt: new Date(),
                updatedAt: new Date()
            };
            this.clients.push(newClient);

            const response: ApiResponse<Client> = {
                success: true,
                data: newClient,
                message: 'Client created successfully'
            };
            res.status(201).json(response);
        } catch (error) {
            const response: ApiResponse = {
                success: false,
                error: 'Failed to create client'
            };
            res.status(500).json(response);
        }
    };

    /**
     * @swagger
     * /api/clients/{id}:
     *   put:
     *     summary: Update an existing client
     *     tags: [Clients]
     *     security:
     *       - bearerAuth: []
     *     parameters:
     *       - in: path
     *         name: id
     *         required: true
     *         schema:
     *           type: string
     *         description: Client ID
     *     requestBody:
     *       required: true
     *       content:
     *         application/json:
     *           schema:
     *             type: object
     *             properties:
     *               name:
     *                 type: string
     *               email:
     *                 type: string
     *                 format: email
     *               company:
     *                 type: string
     *               phone:
     *                 type: string
     *     responses:
     *       200:
     *         description: Client updated successfully
     *       404:
     *         description: Client not found
     *       500:
     *         description: Internal server error
     */
    // RF01.2: Edit existing client
    public updateClient = (req: Request, res: Response): void => {
        try {
            const clientId = req.params.id;
            const updatedData = req.body;
            const clientIndex = this.clients.findIndex(client => client.id === clientId);

            if (clientIndex === -1) {
                const response: ApiResponse = {
                    success: false,
                    error: 'Client not found'
                };
                res.status(404).json(response);
                return;
            }

            this.clients[clientIndex] = {
                ...this.clients[clientIndex],
                ...updatedData,
                updatedAt: new Date()
            };

            const response: ApiResponse<Client> = {
                success: true,
                data: this.clients[clientIndex],
                message: 'Client updated successfully'
            };
            res.status(200).json(response);
        } catch (error) {
            const response: ApiResponse = {
                success: false,
                error: 'Failed to update client'
            };
            res.status(500).json(response);
        }
    };

    /**
     * @swagger
     * /api/clients:
     *   get:
     *     summary: Get all clients with pagination and filters
     *     tags: [Clients]
     *     security:
     *       - bearerAuth: []
     *     parameters:
     *       - in: query
     *         name: page
     *         schema:
     *           type: integer
     *           default: 1
     *         description: Page number
     *       - in: query
     *         name: limit
     *         schema:
     *           type: integer
     *           default: 10
     *         description: Number of items per page
     *       - in: query
     *         name: status
     *         schema:
     *           type: string
     *           enum: [active, inactive]
     *         description: Filter by client status
     *       - in: query
     *         name: search
     *         schema:
     *           type: string
     *         description: Search by name, email, or company
     *     responses:
     *       200:
     *         description: List of clients retrieved successfully
     *         content:
     *           application/json:
     *             schema:
     *               type: object
     *               properties:
     *                 success:
     *                   type: boolean
     *                 data:
     *                   type: array
     *                   items:
     *                     $ref: '#/components/schemas/Client'
     *                 pagination:
     *                   type: object
     *                   properties:
     *                     currentPage:
     *                       type: integer
     *                     totalPages:
     *                       type: integer
     *                     totalClients:
     *                       type: integer
     *                     hasNext:
     *                       type: boolean
     *                     hasPrev:
     *                       type: boolean
     *       500:
     *         description: Internal server error
     */
    // RF01.3: List clients with pagination
    public getClients = (req: Request, res: Response): void => {
        try {
            const page = parseInt(req.query.page as string) || 1;
            const limit = parseInt(req.query.limit as string) || 10;
            const status = req.query.status as string;
            const search = req.query.search as string;

            let filteredClients = this.clients;

            // Filter by status
            if (status) {
                filteredClients = filteredClients.filter(client => client.status === status);
            }

            // Search filter
            if (search) {
                const searchLower = search.toLowerCase();
                filteredClients = filteredClients.filter(client =>
                    client.name.toLowerCase().includes(searchLower) ||
                    client.email.toLowerCase().includes(searchLower) ||
                    (client.company && client.company.toLowerCase().includes(searchLower))
                );
            }

            const startIndex = (page - 1) * limit;
            const endIndex = startIndex + limit;
            const paginatedClients = filteredClients.slice(startIndex, endIndex);

            const response: ApiResponse<Client[]> = {
                success: true,
                data: paginatedClients,
                pagination: {
                    page,
                    limit,
                    total: filteredClients.length,
                    totalPages: Math.ceil(filteredClients.length / limit)
                }
            };
            res.status(200).json(response);
        } catch (error) {
            const response: ApiResponse = {
                success: false,
                error: 'Failed to retrieve clients'
            };
            res.status(500).json(response);
        }
    };

    // RF01.4: Get specific client
    public getClient = (req: Request, res: Response): void => {
        try {
            const clientId = req.params.id;
            const client = this.clients.find(client => client.id === clientId);

            if (!client) {
                const response: ApiResponse = {
                    success: false,
                    error: 'Client not found'
                };
                res.status(404).json(response);
                return;
            }

            const response: ApiResponse<Client> = {
                success: true,
                data: client
            };
            res.status(200).json(response);
        } catch (error) {
            const response: ApiResponse = {
                success: false,
                error: 'Failed to retrieve client'
            };
            res.status(500).json(response);
        }
    };

    // RF01.5: Deactivate/reactivate client
    public deleteClient = (req: Request, res: Response): void => {
        try {
            const clientId = req.params.id;
            const clientIndex = this.clients.findIndex(client => client.id === clientId);

            if (clientIndex === -1) {
                const response: ApiResponse = {
                    success: false,
                    error: 'Client not found'
                };
                res.status(404).json(response);
                return;
            }

            // Instead of deleting, we deactivate
            this.clients[clientIndex].status = 'inactive';
            this.clients[clientIndex].updatedAt = new Date();

            const response: ApiResponse = {
                success: true,
                message: 'Client deactivated successfully'
            };
            res.status(200).json(response);
        } catch (error) {
            const response: ApiResponse = {
                success: false,
                error: 'Failed to deactivate client'
            };
            res.status(500).json(response);
        }
    };

    // RF01.6: Get client history
    public getClientHistory = (req: Request, res: Response): void => {
        try {
            const clientId = req.params.id;
            const client = this.clients.find(client => client.id === clientId);

            if (!client) {
                const response: ApiResponse = {
                    success: false,
                    error: 'Client not found'
                };
                res.status(404).json(response);
                return;
            }

            // Mock history data - in a real implementation, this would come from an audit log
            const history = [
                {
                    id: uuidv4(),
                    action: 'created',
                    timestamp: client.createdAt,
                    details: 'Client account created',
                    performedBy: 'system'
                },
                {
                    id: uuidv4(),
                    action: 'updated',
                    timestamp: client.updatedAt,
                    details: 'Client information updated',
                    performedBy: 'admin'
                }
            ];

            const response: ApiResponse = {
                success: true,
                data: history
            };
            res.status(200).json(response);
        } catch (error) {
            const response: ApiResponse = {
                success: false,
                error: 'Failed to retrieve client history'
            };
            res.status(500).json(response);
        }
    };
}

export default ClientController;
