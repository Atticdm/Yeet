#!/bin/bash

echo "🚀 Yeet Backend Deployment Script"
echo "=================================="

# Check if Railway CLI is installed
if ! command -v railway &> /dev/null; then
    echo "❌ Railway CLI not found. Installing..."
    npm install -g @railway/cli
fi

echo "📦 Installing dependencies..."
npm install

echo "🔧 Testing server locally..."
node simple-server.js &
SERVER_PID=$!
sleep 3

# Test health endpoint
if curl -s http://localhost:3000/health > /dev/null; then
    echo "✅ Server is working locally"
    kill $SERVER_PID
else
    echo "❌ Server failed to start"
    kill $SERVER_PID
    exit 1
fi

echo ""
echo "🌐 Next steps:"
echo "1. Go to https://railway.app"
echo "2. Create new project"
echo "3. Connect GitHub repository"
echo "4. Select 'Server/' folder"
echo "5. Deploy!"
echo ""
echo "📱 After deployment:"
echo "1. Copy the Railway URL"
echo "2. Update Config.plist with the new URL"
echo "3. Build iOS app in Xcode"
echo ""
echo "🎉 Ready for deployment!"
