import {
    Add as AddIcon,
    Delete as DeleteIcon,
    Edit as EditIcon,
    Visibility as ViewIcon
} from '@mui/icons-material';
import {
    Box,
    Button,
    Card,
    CardContent,
    Chip,
    Dialog,
    DialogActions,
    DialogContent,
    DialogTitle,
    IconButton,
    Paper,
    Table,
    TableBody,
    TableCell,
    TableContainer,
    TableHead,
    TableRow,
    TextField,
    Typography
} from '@mui/material';
import React, { useState } from 'react';

interface Client {
    id: string;
    name: string;
    email: string;
    company: string;
    status: 'active' | 'inactive';
    vmsCount: number;
    createdAt: string;
}

const mockClients: Client[] = [
    {
        id: '1',
        name: 'João Silva',
        email: 'joao@empresa.com',
        company: 'Empresa A',
        status: 'active',
        vmsCount: 3,
        createdAt: '2024-01-15'
    },
    {
        id: '2',
        name: 'Maria Santos',
        email: 'maria@startup.com',
        company: 'Startup B',
        status: 'active',
        vmsCount: 5,
        createdAt: '2024-02-20'
    }
];

const Clients: React.FC = () => {
    const [clients] = useState<Client[]>(mockClients);
    const [openDialog, setOpenDialog] = useState(false);
    const [selectedClient, setSelectedClient] = useState<Client | null>(null);

    const getStatusColor = (status: string) => {
        return status === 'active' ? 'success' : 'default';
    };

    const handleViewClient = (client: Client) => {
        setSelectedClient(client);
        setOpenDialog(true);
    };

    return (
        <Box sx={{ p: 3 }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
                <Typography variant="h4">Clientes</Typography>
                <Button variant="contained" startIcon={<AddIcon />}>
                    Novo Cliente
                </Button>
            </Box>

            <Box sx={{ display: 'flex', gap: 2, mb: 3 }}>
                <Card sx={{ flex: 1 }}>
                    <CardContent>
                        <Typography variant="h6" color="primary">
                            {clients.filter(c => c.status === 'active').length}
                        </Typography>
                        <Typography variant="body2" color="text.secondary">
                            Clientes Ativos
                        </Typography>
                    </CardContent>
                </Card>

                <Card sx={{ flex: 1 }}>
                    <CardContent>
                        <Typography variant="h6" color="info.main">
                            {clients.reduce((sum, c) => sum + c.vmsCount, 0)}
                        </Typography>
                        <Typography variant="body2" color="text.secondary">
                            Total de VMs
                        </Typography>
                    </CardContent>
                </Card>

                <Card sx={{ flex: 1 }}>
                    <CardContent>
                        <Typography variant="h6" color="secondary">
                            {clients.length}
                        </Typography>
                        <Typography variant="body2" color="text.secondary">
                            Total de Clientes
                        </Typography>
                    </CardContent>
                </Card>
            </Box>

            <Paper>
                <TableContainer>
                    <Table>
                        <TableHead>
                            <TableRow>
                                <TableCell>Nome</TableCell>
                                <TableCell>Empresa</TableCell>
                                <TableCell>Email</TableCell>
                                <TableCell>Status</TableCell>
                                <TableCell>VMs</TableCell>
                                <TableCell>Data Criação</TableCell>
                                <TableCell>Ações</TableCell>
                            </TableRow>
                        </TableHead>
                        <TableBody>
                            {clients.map((client) => (
                                <TableRow key={client.id} hover>
                                    <TableCell>{client.name}</TableCell>
                                    <TableCell>{client.company}</TableCell>
                                    <TableCell>{client.email}</TableCell>
                                    <TableCell>
                                        <Chip
                                            label={client.status}
                                            color={getStatusColor(client.status) as any}
                                            size="small"
                                        />
                                    </TableCell>
                                    <TableCell>{client.vmsCount}</TableCell>
                                    <TableCell>{client.createdAt}</TableCell>
                                    <TableCell>
                                        <IconButton
                                            size="small"
                                            onClick={() => handleViewClient(client)}
                                        >
                                            <ViewIcon />
                                        </IconButton>
                                        <IconButton size="small">
                                            <EditIcon />
                                        </IconButton>
                                        <IconButton size="small">
                                            <DeleteIcon />
                                        </IconButton>
                                    </TableCell>
                                </TableRow>
                            ))}
                        </TableBody>
                    </Table>
                </TableContainer>
            </Paper>

            <Dialog
                open={openDialog}
                onClose={() => setOpenDialog(false)}
                maxWidth="sm"
                fullWidth
            >
                <DialogTitle>Detalhes do Cliente</DialogTitle>
                <DialogContent>
                    {selectedClient && (
                        <Box sx={{ mt: 2 }}>
                            <TextField
                                fullWidth
                                label="Nome"
                                value={selectedClient.name}
                                margin="normal"
                                InputProps={{ readOnly: true }}
                            />
                            <TextField
                                fullWidth
                                label="Email"
                                value={selectedClient.email}
                                margin="normal"
                                InputProps={{ readOnly: true }}
                            />
                            <TextField
                                fullWidth
                                label="Empresa"
                                value={selectedClient.company}
                                margin="normal"
                                InputProps={{ readOnly: true }}
                            />
                            <TextField
                                fullWidth
                                label="Status"
                                value={selectedClient.status}
                                margin="normal"
                                InputProps={{ readOnly: true }}
                            />
                        </Box>
                    )}
                </DialogContent>
                <DialogActions>
                    <Button onClick={() => setOpenDialog(false)}>Fechar</Button>
                </DialogActions>
            </Dialog>
        </Box>
    );
};

export default Clients;
