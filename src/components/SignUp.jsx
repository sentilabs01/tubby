import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '../../components/ui/card.jsx';
import { Button } from '../../components/ui/button.jsx';
import { Input } from '../../components/ui/input.jsx';
import { Badge } from '../../components/ui/badge.jsx';
import { Alert, AlertDescription } from '../../components/ui/alert.jsx';
import { 
  Mail, 
  Lock, 
  User, 
  Eye, 
  EyeOff, 
  Github, 
  Chrome, 
  UserPlus, 
  ArrowRight,
  CheckCircle,
  AlertCircle
} from 'lucide-react';

const SignUp = ({ onSwitchToLogin }) => {
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    password: '',
    confirmPassword: ''
  });
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(null);

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
    setError(null); // Clear error when user types
  };

  const validateForm = () => {
    if (!formData.name.trim()) {
      setError('Name is required');
      return false;
    }
    if (!formData.email.trim()) {
      setError('Email is required');
      return false;
    }
    if (!/\S+@\S+\.\S+/.test(formData.email)) {
      setError('Please enter a valid email address');
      return false;
    }
    if (formData.password.length < 8) {
      setError('Password must be at least 8 characters long');
      return false;
    }
    if (formData.password !== formData.confirmPassword) {
      setError('Passwords do not match');
      return false;
    }
    return true;
  };

  const handleSignUp = async (e) => {
    e.preventDefault();
    if (!validateForm()) return;

    setLoading(true);
    setError(null);

    try {
      // For now, we'll simulate a sign-up process
      // In a real app, you'd send this to your backend
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      setSuccess('Account created successfully! Redirecting to login...');
      setTimeout(() => {
        onSwitchToLogin();
      }, 2000);
    } catch (err) {
      setError('Failed to create account. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const handleOAuthSignUp = (provider) => {
    setLoading(true);
    setError(null);
    
    // Redirect to OAuth provider
    const backendUrl = import.meta.env.VITE_API_URL;
    window.location.href = `${backendUrl}/auth/${provider}`;
  };

  const handleGuestSignUp = async () => {
    setLoading(true);
    setError(null);

    try {
      const backendUrl = import.meta.env.VITE_API_URL;
      const response = await fetch(`${backendUrl}/auth/guest`, {
        method: 'POST',
        credentials: 'include'
      });

      if (response.ok) {
        const data = await response.json();
        setSuccess('Guest account created! Welcome to Tubby AI.');
        // You might want to redirect to the main app here
        setTimeout(() => {
          window.location.href = '/';
        }, 2000);
      } else {
        setError('Failed to create guest account');
      }
    } catch (err) {
      setError('Network error. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-blue-900 to-purple-900 flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        {/* Header */}
        <div className="text-center mb-8">
          <h1 className="text-4xl font-bold text-white mb-2">Join Tubby AI</h1>
          <p className="text-gray-300">Create your account and start building with AI</p>
        </div>

        {/* Sign Up Card */}
        <Card className="bg-gray-800/50 border-gray-700 backdrop-blur-sm">
          <CardHeader className="text-center">
            <CardTitle className="text-2xl text-white">Create Account</CardTitle>
          </CardHeader>
          <CardContent className="space-y-6">
            {/* Error/Success Messages */}
            {error && (
              <Alert variant="destructive">
                <AlertCircle className="h-4 w-4" />
                <AlertDescription>{error}</AlertDescription>
              </Alert>
            )}
            
            {success && (
              <Alert variant="success">
                <CheckCircle className="h-4 w-4" />
                <AlertDescription>{success}</AlertDescription>
              </Alert>
            )}

            {/* OAuth Buttons */}
            <div className="space-y-3">
              <Button
                onClick={() => handleOAuthSignUp('google')}
                disabled={loading}
                className="w-full bg-white text-gray-900 hover:bg-gray-100 border border-gray-300"
              >
                <Chrome className="w-5 h-5 mr-2" />
                Continue with Google
              </Button>
              
              <Button
                onClick={() => handleOAuthSignUp('github')}
                disabled={loading}
                className="w-full bg-gray-900 text-white hover:bg-gray-800 border border-gray-700"
              >
                <Github className="w-5 h-5 mr-2" />
                Continue with GitHub
              </Button>
            </div>

            {/* Divider */}
            <div className="relative">
              <div className="absolute inset-0 flex items-center">
                <span className="w-full border-t border-gray-600" />
              </div>
              <div className="relative flex justify-center text-xs uppercase">
                <span className="bg-gray-800 px-2 text-gray-400">Or continue with</span>
              </div>
            </div>

            {/* Guest Sign Up */}
            <Button
              onClick={handleGuestSignUp}
              disabled={loading}
              variant="outline"
              className="w-full border-gray-600 text-gray-300 hover:bg-gray-700"
            >
              <UserPlus className="w-5 h-5 mr-2" />
              Continue as Guest
            </Button>

            {/* Traditional Sign Up Form */}
            <form onSubmit={handleSignUp} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-300 mb-2">
                  Full Name
                </label>
                <div className="relative">
                  <User className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4" />
                  <Input
                    type="text"
                    name="name"
                    value={formData.name}
                    onChange={handleInputChange}
                    placeholder="Enter your full name"
                    className="pl-10 bg-gray-700 border-gray-600 text-white placeholder-gray-400"
                    disabled={loading}
                  />
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-300 mb-2">
                  Email Address
                </label>
                <div className="relative">
                  <Mail className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4" />
                  <Input
                    type="email"
                    name="email"
                    value={formData.email}
                    onChange={handleInputChange}
                    placeholder="Enter your email"
                    className="pl-10 bg-gray-700 border-gray-600 text-white placeholder-gray-400"
                    disabled={loading}
                  />
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-300 mb-2">
                  Password
                </label>
                <div className="relative">
                  <Lock className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4" />
                  <Input
                    type={showPassword ? 'text' : 'password'}
                    name="password"
                    value={formData.password}
                    onChange={handleInputChange}
                    placeholder="Create a password"
                    className="pl-10 pr-10 bg-gray-700 border-gray-600 text-white placeholder-gray-400"
                    disabled={loading}
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400 hover:text-gray-300"
                  >
                    {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                  </button>
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-300 mb-2">
                  Confirm Password
                </label>
                <div className="relative">
                  <Lock className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4" />
                  <Input
                    type={showConfirmPassword ? 'text' : 'password'}
                    name="confirmPassword"
                    value={formData.confirmPassword}
                    onChange={handleInputChange}
                    placeholder="Confirm your password"
                    className="pl-10 pr-10 bg-gray-700 border-gray-600 text-white placeholder-gray-400"
                    disabled={loading}
                  />
                  <button
                    type="button"
                    onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                    className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400 hover:text-gray-300"
                  >
                    {showConfirmPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                  </button>
                </div>
              </div>

              <Button
                type="submit"
                disabled={loading}
                className="w-full bg-blue-600 hover:bg-blue-700 text-white"
              >
                {loading ? (
                  <div className="flex items-center">
                    <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                    Creating Account...
                  </div>
                ) : (
                  <div className="flex items-center">
                    Create Account
                    <ArrowRight className="w-4 h-4 ml-2" />
                  </div>
                )}
              </Button>
            </form>

            {/* Switch to Login */}
            <div className="text-center">
              <p className="text-gray-400">
                Already have an account?{' '}
                <button
                  onClick={onSwitchToLogin}
                  className="text-blue-400 hover:text-blue-300 font-medium"
                >
                  Sign in here
                </button>
              </p>
            </div>
          </CardContent>
        </Card>

        {/* Features */}
        <div className="mt-8 grid grid-cols-1 gap-4">
          <div className="bg-gray-800/30 rounded-lg p-4 border border-gray-700">
            <h3 className="text-white font-semibold mb-2">✨ What you'll get:</h3>
            <ul className="text-gray-300 text-sm space-y-1">
              <li>• Access to AI-powered development tools</li>
              <li>• Multi-terminal workspace</li>
              <li>• Real-time collaboration features</li>
              <li>• Advanced code analysis</li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  );
};

export default SignUp; 