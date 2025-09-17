import {
    Add as AddIcon,
    Computer as ComputerIcon,
    Delete as DeleteIcon,
    PlayArrow as StartIcon,
    Stop as StopIcon,
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
    MenuItem,
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

interface VM {
    id: string;
    name: string;
    status: 'running' | 'stopped' | 'pending';
    template: string;
    cpu: number;
    memory: number;
    disk: number;
    client: string;
    ip: string;
    uptime: string;
}

const mockVMs: VM[] = [
    {
        id: '1',
        name: 'nginx-app-01',
        status: 'running',
        template: 'Ubuntu 22.04',
        cpu: 2,
        memory: 4,
        disk: 40,
        client: 'Cliente A',
        ip: '192.168.1.100',
        uptime: '5d 2h 30m'
    },
    {
        id: '2',
        name: 'gitlab-01',
        status: 'running',
        template: 'Ubuntu 22.04',
        cpu: 4,
        memory: 8,
        disk: 80,
        client: 'Cliente B',
        ip: '192.168.1.101',
        uptime: '12d 8h 15m'
    }
];

const VMs: React.FC = () => {
    const [vms] = useState<VM[]>(mockVMs);
    const [openDialog, setOpenDialog] = useState(false);
    const [openDetailDialog, setOpenDetailDialog] = useState(false);
    const [selectedVM, setSelectedVM] = useState<VM | null>(null);

    const getStatusColor = (status: string) => {
        switch (status) {
            case 'running': return 'success';
            case 'stopped': return 'error';
            case 'pending': return 'warning';
            default: return 'default';
        }
    };

    const handleViewVM = (vm: VM) => {
        setSelectedVM(vm);
        setOpenDetailDialog(true);
    };

    return (
        <Box sx={{ p: 3 }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
                <Typography variant="h4" sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <ComputerIcon />
                    Máquinas Virtuais
                </Typography>
                <Button variant="contained" startIcon={<AddIcon />} onClick={() => setOpenDialog(true)}>
                    Nova VM
                </Button>
            </Box>

            <Box sx={{ display: 'flex', gap: 2, mb: 3 }}>
                <Card sx={{ flex: 1 }}>
                    <CardContent>
                        <Typography variant="h6" color="success.main">
                            {vms.filter(vm => vm.status === 'running').length}
                        </Typography>
                        <Typography variant="body2" color="text.secondary">
                            VMs Ativas
                        </Typography>
                    </CardContent>
                </Card>

                <Card sx={{ flex: 1 }}>
                    <CardContent>
                        <Typography variant="h6" color="error.main">
                            {vms.filter(vm => vm.status === 'stopped').length}
                        </Typography>
                        <Typography variant="body2" color="text.secondary">
                            VMs Paradas
                        </Typography>
                    </CardContent>
                </Card>

                <Card sx={{ flex: 1 }}>
                    <CardContent>
                        <Typography variant="h6" color="warning.main">
                            {vms.filter(vm => vm.status === 'pending').length}
                        </Typography>
                        <Typography variant="body2" color="text.secondary">
                            VMs Pendentes
                        </Typography>
                    </CardContent>
                </Card>

                <Card sx={{ flex: 1 }}>
                    <CardContent>
                        <Typography variant="h6" color="primary">
                            {vms.length}
                        </Typography>
                        <Typography variant="body2" color="text.secondary">
                            Total de VMs
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
                                <TableCell>Status</TableCell>
                                <TableCell>Template</TableCell>
                                <TableCell>CPU</TableCell>
                                <TableCell>Memória</TableCell>
                                <TableCell>Disco</TableCell>
                                <TableCell>Cliente</TableCell>
                                <TableCell>IP</TableCell>
                                <TableCell>Ações</TableCell>
                            </TableRow>
                        </TableHead>
                        <TableBody>
                            {vms.map((vm) => (
                                <TableRow key={vm.id} hover>
                                    <TableCell>{vm.name}</TableCell>
                                    <TableCell>
                                        <Chip
                                            label={vm.status}
                                            color={getStatusColor(vm.status) as any}
                                            size="small"
                                        />
                                    </TableCell>
                                    <TableCell>{vm.template}</TableCell>
                                    <TableCell>{vm.cpu} vCPUs</TableCell>
                                    <TableCell>{vm.memory} GB</TableCell>
                                    <TableCell>{vm.disk} GB</TableCell>
                                    <TableCell>{vm.client}</TableCell>
                                    <TableCell>{vm.ip}</TableCell>
                                    <TableCell>
                                        <IconButton
                                            size="small"
                                            onClick={() => handleViewVM(vm)}
                                        >
                                            <ViewIcon />
                                        </IconButton>
                                        {vm.status === 'stopped' ? (
                                            <IconButton size="small" color="success">
                                                <StartIcon />
                                            </IconButton>
                                        ) : (
                                            <IconButton size="small" color="error">
                                                <StopIcon />
                                            </IconButton>
                                        )}
                                        <IconButton size="small" color="error">
                                            <DeleteIcon />
                                        </IconButton>
                                    </TableCell>
                                </TableRow>
                            ))}
                        </TableBody>
                    </Table>
                </TableContainer>
            </Paper>

            {/* New VM Dialog */}
            <Dialog open={openDialog} onClose={() => setOpenDialog(false)} maxWidth="sm" fullWidth>
                <DialogTitle>Nova Máquina Virtual</DialogTitle>
                <DialogContent>
                    <Box sx={{ mt: 2 }}>
                        <TextField
                            fullWidth
                            label="Nome da VM"
                            margin="normal"
                            placeholder="Ex: nginx-app-01"
                        />
                        <TextField
                            fullWidth
                            select
                            label="Template"
                            margin="normal"
                            defaultValue=""
                        >
                            <MenuItem value="ubuntu-22.04">Ubuntu 22.04</MenuItem>
                            <MenuItem value="centos-8">CentOS 8</MenuItem>
                            <MenuItem value="debian-11">Debian 11</MenuItem>
                        </TextField>
                        <TextField
                            fullWidth
                            select
                            label="Cliente"
                            margin="normal"
                            defaultValue=""
                        >
                            <MenuItem value="client-a">Cliente A</MenuItem>
                            <MenuItem value="client-b">Cliente B</MenuItem>
                            <MenuItem value="client-c">Cliente C</MenuItem>
                        </TextField>
                        <TextField
                            fullWidth
                            type="number"
                            label="CPU (vCPUs)"
                            margin="normal"
                            defaultValue={2}
                        />
                        <TextField
                            fullWidth
                            type="number"
                            label="Memória (GB)"
                            margin="normal"
                            defaultValue={4}
                        />
                        <TextField
                            fullWidth
                            type="number"
                            label="Disco (GB)"
                            margin="normal"
                            defaultValue={40}
                        />
                    </Box>
                </DialogContent>
                <DialogActions>
                    <Button onClick={() => setOpenDialog(false)}>Cancelar</Button>
                    <Button variant="contained" onClick={() => setOpenDialog(false)}>
                        Criar VM
                    </Button>
                </DialogActions>
            </Dialog>

            {/* VM Details Dialog */}
            <Dialog
                open={openDetailDialog}
                onClose={() => setOpenDetailDialog(false)}
                maxWidth="md"
                fullWidth
            >
                <DialogTitle>
                    Detalhes da VM: {selectedVM?.name}
                </DialogTitle>
                <DialogContent>
                    {selectedVM && (
                        <Box sx={{ mt: 2 }}>
                            <Box sx={{ display: 'flex', gap: 2, mb: 3, flexWrap: 'wrap' }}>
                                <Box sx={{ flex: 1, minWidth: 200 }}>
                                    <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                                        Status
                                    </Typography>
                                    <Chip
                                        label={selectedVM.status}
                                        color={getStatusColor(selectedVM.status) as any}
                                    />
                                </Box>
                                <Box sx={{ flex: 1, minWidth: 200 }}>
                                    <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                                        Template
                                    </Typography>
                                    <Typography variant="body1">{selectedVM.template}</Typography>
                                </Box>
                                <Box sx={{ flex: 1, minWidth: 200 }}>
                                    <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                                        Cliente
                                    </Typography>
                                    <Typography variant="body1">{selectedVM.client}</Typography>
                                </Box>
                            </Box>

                            <Box sx={{ display: 'flex', gap: 2, mb: 3, flexWrap: 'wrap' }}>
                                <Box sx={{ flex: 1, minWidth: 150 }}>
                                    <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                                        CPU
                                    </Typography>
                                    <Typography variant="body1">{selectedVM.cpu} vCPUs</Typography>
                                </Box>
                                <Box sx={{ flex: 1, minWidth: 150 }}>
                                    <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                                        Memória
                                    </Typography>
                                    <Typography variant="body1">{selectedVM.memory} GB</Typography>
                                </Box>
                                <Box sx={{ flex: 1, minWidth: 150 }}>
                                    <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                                        Disco
                                    </Typography>
                                    <Typography variant="body1">{selectedVM.disk} GB</Typography>
                                </Box>
                                <Box sx={{ flex: 1, minWidth: 150 }}>
                                    <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                                        IP
                                    </Typography>
                                    <Typography variant="body1">{selectedVM.ip}</Typography>
                                </Box>
                            </Box>

                            <Box>
                                <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                                    Uptime
                                </Typography>
                                <Typography variant="body1">{selectedVM.uptime}</Typography>
                            </Box>
                        </Box>
                    )}
                </DialogContent>
                <DialogActions>
                    <Button onClick={() => setOpenDetailDialog(false)}>Fechar</Button>
                </DialogActions>
            </Dialog>
        </Box>
    );
};

export default VMs;
