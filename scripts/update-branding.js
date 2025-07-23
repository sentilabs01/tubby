#!/usr/bin/env node

/**
 * Tubby AI Branding Update Script
 * This script helps update branding references across the project
 */

const fs = require('fs');
const path = require('path');

const brandingUpdates = {
  'Tubby Team': 'Tubby AI Team',
  'AI Agent Communication Platform': 'Tubby AI - Intelligent Agent Communication Platform',
  'tubby-ai-platform': 'tubby-ai',
  'AI Agent': 'Tubby AI',
  'AI agent': 'Tubby AI'
};

function updateFile(filePath, updates) {
  try {
    let content = fs.readFileSync(filePath, 'utf8');
    let updated = false;
    
    for (const [oldText, newText] of Object.entries(updates)) {
      if (content.includes(oldText)) {
        content = content.replace(new RegExp(oldText, 'g'), newText);
        updated = true;
        console.log(`✅ Updated "${oldText}" to "${newText}" in ${filePath}`);
      }
    }
    
    if (updated) {
      fs.writeFileSync(filePath, content, 'utf8');
    }
  } catch (error) {
    console.error(`❌ Error updating ${filePath}:`, error.message);
  }
}

function updateBranding() {
  console.log('🧠 Updating Tubby AI branding across the project...\n');
  
  const filesToUpdate = [
    'README.md',
    'CONTRIBUTING.md',
    'LICENSE',
    'package.json',
    'index.html',
    'App.jsx',
    'mcp_test_commands.md'
  ];
  
  filesToUpdate.forEach(file => {
    if (fs.existsSync(file)) {
      updateFile(file, brandingUpdates);
    }
  });
  
  console.log('\n🎉 Branding update complete!');
  console.log('📝 Remember to:');
  console.log('   - Update any additional files with branding references');
  console.log('   - Test the application to ensure everything works');
  console.log('   - Commit and push your changes');
}

if (require.main === module) {
  updateBranding();
}

module.exports = { updateBranding, brandingUpdates }; 