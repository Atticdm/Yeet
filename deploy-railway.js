#!/usr/bin/env node

const https = require('https');
const fs = require('fs');
const path = require('path');

// Railway API configuration
const RAILWAY_API_URL = 'https://backboard.railway.app/graphql/v1';
const PROJECT_ID = '9d56f497-921a-4f79-ac92-1a217665d506';

// GraphQL mutation for deployment
const DEPLOY_MUTATION = `
  mutation DeployProject($input: DeployProjectInput!) {
    deployProject(input: $input) {
      id
      status
      url
    }
  }
`;

async function deployToRailway() {
  console.log('🚀 Starting Railway deployment...');
  
  // Check if we have Railway token
  const token = process.env.RAILWAY_TOKEN;
  if (!token) {
    console.error('❌ RAILWAY_TOKEN environment variable is required');
    console.log('Please set your Railway token:');
    console.log('export RAILWAY_TOKEN=your_token_here');
    process.exit(1);
  }

  try {
    const response = await makeGraphQLRequest(DEPLOY_MUTATION, {
      input: {
        projectId: PROJECT_ID,
        source: 'github',
        repository: 'Atticdm/Yeet',
        branch: 'main'
      }
    });

    console.log('✅ Deployment started successfully!');
    console.log('📱 Project ID:', PROJECT_ID);
    console.log('🔗 Check your Railway dashboard for deployment status');
    
  } catch (error) {
    console.error('❌ Deployment failed:', error.message);
    process.exit(1);
  }
}

function makeGraphQLRequest(query, variables) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify({
      query,
      variables
    });

    const options = {
      hostname: 'backboard.railway.app',
      port: 443,
      path: '/graphql/v1',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': data.length,
        'Authorization': `Bearer ${process.env.RAILWAY_TOKEN}`
      }
    };

    const req = https.request(options, (res) => {
      let responseData = '';
      
      res.on('data', (chunk) => {
        responseData += chunk;
      });
      
      res.on('end', () => {
        try {
          const result = JSON.parse(responseData);
          if (result.errors) {
            reject(new Error(result.errors[0].message));
          } else {
            resolve(result.data);
          }
        } catch (error) {
          reject(new Error('Invalid JSON response'));
        }
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    req.write(data);
    req.end();
  });
}

// Run deployment
deployToRailway();
