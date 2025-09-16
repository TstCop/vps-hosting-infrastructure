class ClientController {
    private clients: any[] = [];

    public createClient(clientData: any): any {
        const newClient = { id: this.clients.length + 1, ...clientData };
        this.clients.push(newClient);
        return newClient;
    }

    public updateClient(clientId: number, updatedData: any): any {
        const clientIndex = this.clients.findIndex(client => client.id === clientId);
        if (clientIndex === -1) {
            throw new Error('Client not found');
        }
        this.clients[clientIndex] = { ...this.clients[clientIndex], ...updatedData };
        return this.clients[clientIndex];
    }

    public deleteClient(clientId: number): void {
        const clientIndex = this.clients.findIndex(client => client.id === clientId);
        if (clientIndex === -1) {
            throw new Error('Client not found');
        }
        this.clients.splice(clientIndex, 1);
    }

    public getClient(clientId: number): any {
        const client = this.clients.find(client => client.id === clientId);
        if (!client) {
            throw new Error('Client not found');
        }
        return client;
    }

    public getAllClients(): any[] {
        return this.clients;
    }
}

export default ClientController;