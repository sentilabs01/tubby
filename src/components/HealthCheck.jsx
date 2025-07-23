import React, { useState, useEffect } from 'react';
import offlineModeManager from '../utils/offlineMode.js';

const HealthCheck = () => {
  const [backendStatus, setBackendStatus] = useState('checking');
  const [lastCheck, setLastCheck] = useState(null);
  const [isOfflineMode, setIsOfflineMode] = useState(false);

  useEffect(() => {
    // Check if offline mode is enabled
    setIsOfflineMode(localStorage.getItem('offline_mode') === 'true');
    
    // Perform initial health check
    checkBackendHealth();
    
    // Set up periodic health checks
    const interval = setInterval(checkBackendHealth, 30000); // Check every 30 seconds
    
    return () => clearInterval(interval);
  }, []);

  const checkBackendHealth = async () => {
    try {
      setBackendStatus('checking');
      
      const response = await fetch('/health', {
        method: 'GET',
        timeout: 5000
      });
      
      if (response.ok) {
        setBackendStatus('healthy');
        setLastCheck(new Date());
      } else {
        setBackendStatus('unhealthy');
        setLastCheck(new Date());
      }
    } catch (error) {
      console.log('Backend health check failed:', error);
      setBackendStatus('offline');
      setLastCheck(new Date());
    }
  };

  const enableOfflineMode = () => {
    offlineModeManager.forceOfflineMode();
    setIsOfflineMode(true);
  };

  const disableOfflineMode = () => {
    offlineModeManager.disableOfflineMode();
    setIsOfflineMode(false);
    window.location.reload();
  };

  const getStatusColor = () => {
    switch (backendStatus) {
      case 'healthy':
        return 'text-green-600';
      case 'unhealthy':
        return 'text-yellow-600';
      case 'offline':
        return 'text-red-600';
      default:
        return 'text-gray-600';
    }
  };

  const getStatusIcon = () => {
    switch (backendStatus) {
      case 'healthy':
        return '🟢';
      case 'unhealthy':
        return '🟡';
      case 'offline':
        return '🔴';
      default:
        return '⚪';
    }
  };

  return (
    <div className="fixed bottom-4 right-4 bg-white border border-gray-200 rounded-lg shadow-lg p-4 max-w-sm">
      <div className="flex items-center justify-between mb-2">
        <h3 className="text-sm font-semibold text-gray-800">System Status</h3>
        <button
          onClick={checkBackendHealth}
          className="text-xs text-blue-600 hover:text-blue-800"
        >
          Refresh
        </button>
      </div>
      
      <div className="space-y-2">
        <div className="flex items-center justify-between">
          <span className="text-xs text-gray-600">Backend:</span>
          <span className={`text-xs font-medium ${getStatusColor()}`}>
            {getStatusIcon()} {backendStatus}
          </span>
        </div>
        
        {lastCheck && (
          <div className="text-xs text-gray-500">
            Last check: {lastCheck.toLocaleTimeString()}
          </div>
        )}
        
        <div className="flex items-center justify-between">
          <span className="text-xs text-gray-600">Offline Mode:</span>
          <span className={`text-xs font-medium ${isOfflineMode ? 'text-green-600' : 'text-gray-600'}`}>
            {isOfflineMode ? '🟢 Enabled' : '⚪ Disabled'}
          </span>
        </div>
      </div>
      
      <div className="mt-3 space-y-2">
        {backendStatus === 'offline' && !isOfflineMode && (
          <button
            onClick={enableOfflineMode}
            className="w-full px-3 py-1 text-xs bg-yellow-100 text-yellow-800 rounded hover:bg-yellow-200 transition-colors"
          >
            Enable Offline Mode
          </button>
        )}
        
        {isOfflineMode && (
          <button
            onClick={disableOfflineMode}
            className="w-full px-3 py-1 text-xs bg-blue-100 text-blue-800 rounded hover:bg-blue-200 transition-colors"
          >
            Disable Offline Mode
          </button>
        )}
        
        {backendStatus === 'offline' && (
          <div className="text-xs text-red-600 bg-red-50 p-2 rounded">
            Backend appears to be offline. Some features may not work.
          </div>
        )}
      </div>
    </div>
  );
};

export default HealthCheck; 