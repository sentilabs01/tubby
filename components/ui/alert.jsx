import React from 'react';

const Alert = ({ variant = "default", className = "", children, ...props }) => {
  const baseClasses = "rounded-lg border p-4";
  
  const variantClasses = {
    default: "bg-background text-foreground",
    destructive: "border-destructive/50 text-destructive dark:border-destructive [&>svg]:text-destructive",
    success: "border-green-500/50 text-green-700 dark:text-green-400 [&>svg]:text-green-500",
    warning: "border-yellow-500/50 text-yellow-700 dark:text-yellow-400 [&>svg]:text-yellow-500",
    info: "border-blue-500/50 text-blue-700 dark:text-blue-400 [&>svg]:text-blue-500"
  };

  return (
    <div
      className={`${baseClasses} ${variantClasses[variant]} ${className}`}
      {...props}
    >
      {children}
    </div>
  );
};

const AlertDescription = ({ className = "", children, ...props }) => {
  return (
    <div
      className={`text-sm [&_p]:leading-relaxed ${className}`}
      {...props}
    >
      {children}
    </div>
  );
};

export { Alert, AlertDescription }; 