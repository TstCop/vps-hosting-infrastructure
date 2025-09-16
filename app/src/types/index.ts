export type Client = {
    id: string;
    name: string;
    email: string;
    createdAt: Date;
    updatedAt: Date;
};

export type VM = {
    id: string;
    clientId: string;
    name: string;
    status: 'running' | 'stopped' | 'suspended';
    createdAt: Date;
    updatedAt: Date;
};

export type VagrantConfig = {
    box: string;
    network: {
        type: string;
        ip: string;
    };
    provisioners: Array<{
        type: string;
        script: string;
    }>;
};