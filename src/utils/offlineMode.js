/**
 * Offline Mode Utility for Tubby AI
 * Handles backend fallback and offline functionality
 */

class OfflineModeManager {
  constructor() {
    this.isOfflineMode = localStorage.getItem('offline_mode') === 'true';
    this.originalFetch = window.fetch;
    this.originalWebSocket = window.WebSocket;
    this.blockedUrls = [
      'elasticbeanstalk.com',
      'tubby-backend-prod',
      'api.tubbyai.com'
    ];
    
    this.init();
  }

  init() {
    if (this.isOfflineMode) {
      this.enableOfflineMode();
    }
  }

  enableOfflineMode() {
    console.log('🚫 Enabling offline mode - blocking backend calls');
    
    // Override fetch to skip backend calls
    window.fetch = (url, options) => {
      if (this.shouldBlockUrl(url)) {
        console.log('🚫 Blocked backend call:', url);
        return this.createMockResponse({ success: false, offline: true });
      }
      return this.originalFetch(url, options);
    };

    // Override WebSocket to prevent connection attempts
    window.WebSocket = (url, protocols) => {
      if (this.shouldBlockUrl(url)) {
        console.log('🚫 Blocked WebSocket connection:', url);
        return this.createMockWebSocket();
      }
      return new this.originalWebSocket(url, protocols);
    };

    // Store offline mode state
    localStorage.setItem('offline_mode', 'true');
  }

  disableOfflineMode() {
    console.log('✅ Disabling offline mode - restoring backend calls');
    
    // Restore original functions
    window.fetch = this.originalFetch;
    window.WebSocket = this.originalWebSocket;
    
    // Remove offline mode state
    localStorage.removeItem('offline_mode');
    this.isOfflineMode = false;
  }

  shouldBlockUrl(url) {
    return this.blockedUrls.some(blockedUrl => url.includes(blockedUrl));
  }

  createMockResponse(data) {
    return Promise.resolve(new Response(JSON.stringify(data), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    }));
  }

  createMockWebSocket() {
    return {
      send: () => {},
      close: () => {},
      addEventListener: () => {},
      removeEventListener: () => {},
      readyState: 3, // CLOSED
      CONNECTING: 0,
      OPEN: 1,
      CLOSING: 2,
      CLOSED: 3
    };
  }

  // Check if user is authenticated from local storage
  getStoredUser() {
    const storedUser = localStorage.getItem('tubby_user');
    if (storedUser) {
      try {
        return JSON.parse(storedUser);
      } catch (e) {
        console.error('Failed to parse stored user:', e);
        return null;
      }
    }
    return null;
  }

  // Force offline mode and reload
  forceOfflineMode() {
    this.enableOfflineMode();
    const user = this.getStoredUser();
    if (user) {
      console.log('✅ User authenticated from local storage:', user);
      window.location.reload();
    } else {
      console.log('❌ No user data found');
    }
  }

  // Check backend health
  async checkBackendHealth() {
    try {
      const response = await this.originalFetch('/health', {
        method: 'GET',
        timeout: 5000
      });
      return response.ok;
    } catch (error) {
      console.log('Backend health check failed:', error);
      return false;
    }
  }

  // Auto-detect and enable offline mode if backend is down
  async autoDetectOfflineMode() {
    const isHealthy = await this.checkBackendHealth();
    if (!isHealthy && !this.isOfflineMode) {
      console.log('🔍 Backend appears to be down, enabling offline mode');
      this.forceOfflineMode();
    }
  }
}

// Create global instance
const offlineModeManager = new OfflineModeManager();

// Export for use in other modules
export default offlineModeManager;

// Auto-detect offline mode on page load
if (typeof window !== 'undefined') {
  window.addEventListener('load', () => {
    // Small delay to let the app initialize
    setTimeout(() => {
      offlineModeManager.autoDetectOfflineMode();
    }, 1000);
  });
} 