import React, { useState } from 'react';
import Login from './Login';
import SignUp from './SignUp';

const AuthContainer = () => {
  const [isLogin, setIsLogin] = useState(true);

  const switchToSignUp = () => {
    setIsLogin(false);
  };

  const switchToLogin = () => {
    setIsLogin(true);
  };

  return (
    <div>
      {isLogin ? (
        <Login onSwitchToSignUp={switchToSignUp} />
      ) : (
        <SignUp onSwitchToLogin={switchToLogin} />
      )}
    </div>
  );
};

export default AuthContainer; 