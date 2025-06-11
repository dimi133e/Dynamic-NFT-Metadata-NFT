# 🎨 Dynamic NFT Metadata Contract

A Clarity smart contract that creates NFTs with dynamic metadata that changes based on on-chain activity! 🚀

## 🌟 Features

- 🎯 **Dynamic Metadata**: NFT images and properties change based on user activity
- 📈 **Level System**: NFTs level up as users interact with them
- ⚡ **Activity Tracking**: Monitors user transactions and interactions
- 🔄 **Real-time Updates**: Metadata updates automatically with each interaction
- 👑 **Experience Points**: Earn XP through on-chain activities

## 🎮 How It Works

1. **Mint NFT** 🎨: Contract owner mints NFTs with base metadata
2. **Interact & Earn** ⭐: Users interact with NFTs to gain experience points
3. **Level Up** 🆙: NFTs automatically level up when reaching XP thresholds
4. **Dynamic Images** 🖼️: Metadata URI changes to reflect current level
5. **Activity Decay** ⏰: Activity scores decay over time to encourage engagement

## 🛠️ Core Functions

### Public Functions

- `mint-nft` - Mint new dynamic NFT (owner only)
- `transfer` - Transfer NFT and update activity
- `interact-with-nft` - Interact with owned NFT to gain XP
- `update-activity` - Update user activity metrics
- `force-update-metadata` - Manually trigger metadata update

### Read-Only Functions

- `get-token-uri` - Get dynamic metadata URI
- `get-token-metadata` - Get complete NFT metadata
- `get-user-activity` - Get user activity stats
- `get-nft-level` - Get current NFT level
- `get-activity-summary` - Get detailed activity summary

## 🚀 Usage Examples

### Deploy Contract
```bash
clarinet deploy
```

### Mint Your First Dynamic NFT
```bash
clarinet console
(contract-call? .dynamic-NFT-metadata-NFT mint-nft 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE "My Dynamic NFT" "This NFT evolves with activity" "https://api.example.com/metadata")
```

### Interact and Level Up
```bash
(contract-call? .dynamic-NFT-metadata-NFT interact-with-nft u1)
```

### Check NFT Level
```bash
(contract-call? .dynamic-NFT-metadata-NFT get-nft-level u1)
```

## 📊 Level System

- **Level 1-10**: Available levels
- **XP Threshold**: 100 XP per level
- **Activity Bonus**: +10 XP per interaction
- **Decay Period**: 1000 blocks of inactivity

## 🎯 Learning Objectives

This contract teaches:
- ✅ Dynamic metadata URI generation
- ✅ On-chain activity tracking
- ✅ NFT state management
- ✅ Experience and leveling systems
- ✅ Time-based mechanics

## 🔧 Configuration

Key constants you can modify:
- `LEVEL-UP-THRESHOLD`: XP needed per level (default: 100)
- `ACTIVITY-DECAY-BLOCKS`: Blocks before activity decay (default: 1000)
- `MAX-LEVEL`: Maximum achievable level (default: 10)

## 🎨 Metadata Structure

Dynamic URIs follow this pattern:
```
{base-uri}/level-{current-level}.json
```

Example: `https://api.example.com/metadata/level-5.json`

## 🚦 Getting Started

1. Clone this repository
2. Install Clarinet
3. Run `clarinet check` to verify contract
4. Deploy to testnet with `clarinet deploy`
5. Start minting and interacting! 🎉

## 💡 Pro Tips

- 🔥 Regular interactions keep your NFT's activity score high
- 🎯 Transfer NFTs to boost both sender and receiver activity
- ⚡ Use `force-update-metadata` to refresh your NFT's state
- 📈 Monitor activity decay to maintain high levels

Happy coding! 🎊
```

**Git Commit Message:**
```
feat: implement dynamic NFT metadata contract with activity-based leveling system
```

**GitHub Pull Request Title:**
```
🎨 Add Dynamic NFT Metadata Contract with Activity-Based Evolution
```

**GitHub Pull Request Description:**
```
## 🚀 Dynamic NFT Metadata MVP

This PR introduces a complete dynamic NFT system where metadata and images change based on on-chain activity.

### ✨ What's Added
- Dynamic NFT contract with activity-based metadata updates
- Level system (1-10) with XP thresholds
- Real-time activity tracking and scoring
- Time-based activity decay mechanics
- Comprehensive read/write functions for NFT management

### 🎯 Key Features
- NFT images change based on current level
- Users earn XP through interactions and transfers  
- Activity scores decay over time to encourage engagement
- Owner controls for minting and bulk operations
- Complete metadata URI generation system

### 📚 Learning Focus
Perfect for understanding dynamic metadata URIs, on-chain state management, and activity-based NFT mechanics.

Ready for testing and deployment! 🎉

