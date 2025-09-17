import {
  CloudQueue as CloudIcon,
  Computer as ComputerIcon,
  People as PeopleIcon,
  Warning as WarningIcon,
} from '@mui/icons-material';
import {
  Box,
  Card,
  CardContent,
  LinearProgress,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Typography,
} from '@mui/material';
import {
  CategoryScale,
  Chart as ChartJS,
  Legend,
  LinearScale,
  LineElement,
  PointElement,
  Title,
  Tooltip,
} from 'chart.js';
import React, { useEffect, useState } from 'react';
import { Line } from 'react-chartjs-2';

ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend
);

interface DashboardData {
  totalVMs: number;
  activeVMs: number;
  stoppedVMs: number;
  totalClients: number;
  activeClients: number;
  cpuUsage: number;
  memoryUsage: number;
  diskUsage: number;
  networkUsage: number;
}

interface VMData {
  id: string;
  name: string;
  status: 'running' | 'stopped' | 'pending';
  client: string;
  cpu: number;
  memory: number;
  uptime: string;
}

const Dashboard: React.FC = () => {
  const [data, setData] = useState<DashboardData>({
    totalVMs: 0,
    activeVMs: 0,
    stoppedVMs: 0,
    totalClients: 0,
    activeClients: 0,
    cpuUsage: 0,
    memoryUsage: 0,
    diskUsage: 0,
    networkUsage: 0,
  });

  const [vms, setVMs] = useState<VMData[]>([]);

  useEffect(() => {
    const fetchData = async () => {
      try {
        // Use mock data directly since API methods don't exist yet
        setData({
          totalVMs: 12,
          activeVMs: 10,
          stoppedVMs: 2,
          totalClients: 8,
          activeClients: 6,
          cpuUsage: 45,
          memoryUsage: 62,
          diskUsage: 38,
          networkUsage: 25,
        });

        setVMs([
          { id: '1', name: 'nginx-app-01', status: 'running', client: 'Client A', cpu: 15, memory: 45, uptime: '5d 2h' },
          { id: '2', name: 'gitlab-01', status: 'running', client: 'Client B', cpu: 32, memory: 78, uptime: '12d 8h' },
          { id: '3', name: 'db-server-01', status: 'stopped', client: 'Client A', cpu: 0, memory: 0, uptime: '0' },
          { id: '4', name: 'web-server-02', status: 'running', client: 'Client C', cpu: 8, memory: 25, uptime: '2d 4h' },
          { id: '5', name: 'backup-server', status: 'pending', client: 'Client B', cpu: 55, memory: 85, uptime: '1h 30m' },
        ]);
      } catch (error) {
        console.error('Error fetching dashboard data:', error);
      }
    };

    fetchData();
  }, []);

  const chartData = {
    labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
    datasets: [
      {
        label: 'CPU Usage (%)',
        data: [30, 35, 32, 45, 38, 42],
        borderColor: 'rgb(75, 192, 192)',
        backgroundColor: 'rgba(75, 192, 192, 0.2)',
        tension: 0.1,
      },
      {
        label: 'Memory Usage (%)',
        data: [50, 55, 48, 62, 58, 65],
        borderColor: 'rgb(255, 99, 132)',
        backgroundColor: 'rgba(255, 99, 132, 0.2)',
        tension: 0.1,
      },
    ],
  };

  const chartOptions = {
    responsive: true,
    plugins: {
      legend: {
        position: 'top' as const,
      },
      title: {
        display: true,
        text: 'Sistema de Recursos - Últimos 6 Meses',
      },
    },
    scales: {
      y: {
        beginAtZero: true,
        max: 100,
      },
    },
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'running': return 'success';
      case 'stopped': return 'error';
      case 'pending': return 'warning';
      default: return 'default';
    }
  };

  return (
    <Box sx={{ p: 3 }}>
      <Typography variant="h4" gutterBottom>
        Dashboard
      </Typography>

      {/* Stats Cards */}
      <Box sx={{ display: 'flex', gap: 3, mb: 3, flexWrap: 'wrap' }}>
        <Card sx={{ minWidth: 200, flex: 1 }}>
          <CardContent>
            <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
              <ComputerIcon color="primary" sx={{ mr: 1 }} />
              <Typography color="textSecondary" gutterBottom>
                VMs Ativas
              </Typography>
            </Box>
            <Typography variant="h5" component="div">
              {data.activeVMs}
            </Typography>
            <Typography variant="body2" color="textSecondary">
              de {data.totalVMs} total
            </Typography>
          </CardContent>
        </Card>

        <Card sx={{ minWidth: 200, flex: 1 }}>
          <CardContent>
            <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
              <PeopleIcon color="secondary" sx={{ mr: 1 }} />
              <Typography color="textSecondary" gutterBottom>
                Clientes Ativos
              </Typography>
            </Box>
            <Typography variant="h5" component="div">
              {data.activeClients}
            </Typography>
            <Typography variant="body2" color="textSecondary">
              de {data.totalClients} total
            </Typography>
          </CardContent>
        </Card>

        <Card sx={{ minWidth: 200, flex: 1 }}>
          <CardContent>
            <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
              <CloudIcon color="info" sx={{ mr: 1 }} />
              <Typography color="textSecondary" gutterBottom>
                Armazenamento
              </Typography>
            </Box>
            <Typography variant="h5" component="div">
              {data.diskUsage}%
            </Typography>
            <Typography variant="body2" color="textSecondary">
              em uso
            </Typography>
          </CardContent>
        </Card>

        <Card sx={{ minWidth: 200, flex: 1 }}>
          <CardContent>
            <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
              <WarningIcon color="warning" sx={{ mr: 1 }} />
              <Typography color="textSecondary" gutterBottom>
                VMs Paradas
              </Typography>
            </Box>
            <Typography variant="h5" component="div">
              {data.stoppedVMs}
            </Typography>
            <Typography variant="body2" color="textSecondary">
              necessitam atenção
            </Typography>
          </CardContent>
        </Card>
      </Box>

      {/* Resource Usage */}
      <Box sx={{ display: 'flex', gap: 3, mb: 4, flexWrap: 'wrap' }}>
        <Card sx={{ flex: 1, minWidth: 300 }}>
          <CardContent>
            <Typography variant="h6" gutterBottom>CPU Global</Typography>
            <Box sx={{ mb: 1 }}>
              <Typography variant="body2" color="textSecondary">
                {data.cpuUsage}% utilizado
              </Typography>
            </Box>
            <LinearProgress variant="determinate" value={data.cpuUsage} sx={{ height: 8, borderRadius: 4 }} />
          </CardContent>
        </Card>

        <Card sx={{ flex: 1, minWidth: 300 }}>
          <CardContent>
            <Typography variant="h6" gutterBottom>Memória Global</Typography>
            <Box sx={{ mb: 1 }}>
              <Typography variant="body2" color="textSecondary">
                {data.memoryUsage}% utilizado
              </Typography>
            </Box>
            <LinearProgress variant="determinate" value={data.memoryUsage} sx={{ height: 8, borderRadius: 4 }} />
          </CardContent>
        </Card>

        <Card sx={{ flex: 1, minWidth: 300 }}>
          <CardContent>
            <Typography variant="h6" gutterBottom>Disco Global</Typography>
            <Box sx={{ mb: 1 }}>
              <Typography variant="body2" color="textSecondary">
                {data.diskUsage}% utilizado
              </Typography>
            </Box>
            <LinearProgress variant="determinate" value={data.diskUsage} sx={{ height: 8, borderRadius: 4 }} />
          </CardContent>
        </Card>
      </Box>

      <Box sx={{ display: 'flex', gap: 3, flexWrap: 'wrap' }}>
        {/* Chart */}
        <Card sx={{ flex: 2, minWidth: 400 }}>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              Uso de Recursos
            </Typography>
            <Line data={chartData} options={chartOptions} />
          </CardContent>
        </Card>

        {/* Recent VMs */}
        <Card sx={{ flex: 1, minWidth: 300 }}>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              VMs Recentes
            </Typography>
            <TableContainer>
              <Table size="small">
                <TableHead>
                  <TableRow>
                    <TableCell>Nome</TableCell>
                    <TableCell>Status</TableCell>
                    <TableCell>CPU</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {vms.map((vm) => (
                    <TableRow key={vm.id}>
                      <TableCell>{vm.name}</TableCell>
                      <TableCell>
                        <Typography
                          variant="body2"
                          color={`${getStatusColor(vm.status)}.main`}
                        >
                          {vm.status}
                        </Typography>
                      </TableCell>
                      <TableCell>{vm.cpu}%</TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </TableContainer>
          </CardContent>
        </Card>
      </Box>
    </Box>
  );
};

export default Dashboard;
