import { Request, Response } from 'express';

class ClientController {
    private clients: any[] = [];

    public createClient = (req: Request, res: Response): void => {
        const clientData = req.body;
        const newClient = { id: this.clients.length + 1, ...clientData };
        this.clients.push(newClient);
        res.status(201).json(newClient);
    };

    public updateClient = (req: Request, res: Response): void => {
        const clientId = parseInt(req.params.id);
        const updatedData = req.body;
        const clientIndex = this.clients.findIndex(client => client.id === clientId);
        if (clientIndex === -1) {
            res.status(404).json({ error: 'Client not found' });
            return;
        }
        this.clients[clientIndex] = { ...this.clients[clientIndex], ...updatedData };
        res.status(200).json(this.clients[clientIndex]);
    };

    public deleteClient = (req: Request, res: Response): void => {
        const clientId = parseInt(req.params.id);
        const clientIndex = this.clients.findIndex(client => client.id === clientId);
        if (clientIndex === -1) {
            res.status(404).json({ error: 'Client not found' });
            return;
        }
        this.clients.splice(clientIndex, 1);
        res.status(204).send();
    };

    public getClient = (req: Request, res: Response): void => {
        const clientId = parseInt(req.params.id);
        const client = this.clients.find(client => client.id === clientId);
        if (!client) {
            res.status(404).json({ error: 'Client not found' });
            return;
        }
        res.status(200).json(client);
    };

    public getClients = (req: Request, res: Response): void => {
        res.status(200).json(this.clients);
    };
}

export default ClientController;