import { Box } from '@mui/material';
import CssBaseline from '@mui/material/CssBaseline';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import { Route, BrowserRouter as Router, Routes } from 'react-router-dom';
import Header from './components/Layout/Header';
import Sidebar from './components/Layout/Sidebar';
import ClientsPage from './pages/Clients';
import Dashboard from './pages/Dashboard';
import LogsPage from './pages/Logs';
import MonitoringPage from './pages/Monitoring';
import TemplatesPage from './pages/Templates';
import VMsPage from './pages/VMs';

const theme = createTheme({
  palette: {
    mode: 'light',
    primary: {
      main: '#1976d2',
    },
    secondary: {
      main: '#dc004e',
    },
    background: {
      default: '#f5f5f5',
    },
  },
});

function App() {
  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <Router>
        <Box sx={{ display: 'flex', minHeight: '100vh' }}>
          <Sidebar />
          <Box sx={{ flexGrow: 1, display: 'flex', flexDirection: 'column' }}>
            <Header />
            <Box
              component="main"
              sx={{
                flexGrow: 1,
                p: 3,
                backgroundColor: 'background.default',
                overflow: 'auto'
              }}
            >
              <Routes>
                <Route path="/" element={<Dashboard />} />
                <Route path="/clients" element={<ClientsPage />} />
                <Route path="/vms" element={<VMsPage />} />
                <Route path="/templates" element={<TemplatesPage />} />
                <Route path="/monitoring" element={<MonitoringPage />} />
                <Route path="/logs" element={<LogsPage />} />
              </Routes>
            </Box>
          </Box>
        </Box>
      </Router>
    </ThemeProvider>
  );
}

export default App;
