```markdown
# Web3 Blockchain Crowdfunding Platform (Kickstarter DApp)

A full-stack, decentralized crowdfunding platform built on the Ethereum blockchain. This application allows creators to publish creative campaigns, set funding targets and deadlines, and receive direct cryptocurrency donations from supporters worldwide without third-party intermediaries or central processing fees.

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Key Features](#-key-features)
- [Tech Stack](#-tech-stack)
- [Architecture & Directory Structure](#-architecture--directory-structure)
- [Smart Contract Specification](#-smart-contract-specification)
- [Prerequisites](#-prerequisites)
- [Installation & Setup](#-installation--setup)
- [Environment Variables](#-environment-variables)
- [Usage Guide](#-usage-guide)
- [Deployment](#-deployment)
- [License](#-license)

---

## 📌 Overview

Traditional crowdfunding platforms charge high platform fees, impose regional payout restrictions, and retain centralized control over campaign funds. This Web3 Crowdfunding Platform solves these pain points by leveraging immutable smart contracts on the Ethereum blockchain:

- **Direct Peer-to-Peer Funding**: Donated ETH is transferred directly to the campaign creator's crypto wallet in real-time.
- **Transparency & Security**: Campaign targets, deadlines, raised amounts, and backer contribution histories are permanently recorded on-chain.
- **Global Accessibility**: Anyone with a Web3 wallet (e.g., MetaMask) can create or fund a campaign from anywhere in the world.

---

## ✨ Key Features

- 🦊 **MetaMask Wallet Integration**: One-click wallet pairing via Thirdweb SDK.
- 🚀 **Campaign Creation**: Launch new campaigns specifying campaign title, story/description, target goal (in ETH), deadline date, and banner image URL.
- 💸 **On-Chain Donations**: Fund active campaigns directly using Ethereum testnet funds (Sepolia / Goerli).
- 📊 **Real-Time Campaign Metrics**:
  - Dynamically calculated funding progress bar (`%` raised vs. target).
  - Countdown indicator for remaining days.
  - Complete list of campaign backers with their wallet addresses and individual donation amounts.
- 👤 **User Profile & Filtering**: View all active campaigns created specifically by your connected wallet address.
- 🔍 **Interactive Navigation & Search**: Filter campaigns by keywords and seamlessly navigate via responsive sidebar and drawer menus.
- ⏳ **Transaction Loading Overlay**: User feedback during wallet confirmation and block verification.
- 📱 **Fully Responsive UI**: Modern dark-mode interface styled with Tailwind CSS, optimized for mobile, tablet, and desktop viewports.

---

## 🛠 Tech Stack

### **Smart Contract & Blockchain**
- **Solidity** (`^0.8.9`) — Smart contract programming language.
- **Hardhat** — Ethereum development environment for compiling and testing contracts.
- **Thirdweb SDK & Framework** (`@thirdweb-dev/contract-type`, `@thirdweb-dev/sdk`) — Streamlined contract deployment, ABI management, and dashboard administration.
- **Ethers.js** (`v5`) — Blockchain interaction and utility formatting (e.g., `parseEther`, `formatEther`).

### **Frontend & User Interface**
- **React.js** (`v18`) with **Vite** — Fast, modern frontend framework and build tool.
- **Thirdweb React SDK** (`@thirdweb-dev/react`) — Context provider and custom hooks (`useAddress`, `useContract`, `useMetamask`, `useContractWrite`).
- **React Router Dom** (`v6`) — Client-side route management and navigation state passing.
- **Tailwind CSS** — Utility-first CSS framework customized with the *Epilogue* font family and dark color palette.

---

## 📁 Architecture & Directory Structure

```text
crowdfunding/
├── web3/                       # Smart Contract Development Environment
│   ├── contracts/
│   │   └── Crowdfunding.sol    # Core Solidity Smart Contract
│   ├── .env                    # Private key configuration (Git-ignored)
│   ├── hardhat.config.js       # Hardhat network & RPC settings
│   └── package.json
│
└── client/                     # React + Vite Frontend Web Application
    ├── public/                 # Static assets
    ├── src/
    │   ├── assets/             # SVGs, icons, and loader graphics
    │   ├── components/         # Reusable UI components
    │   │   ├── CountBox.jsx    # Metric display card (Days left, Raised ETH, Backers)
    │   │   ├── CustomButton.jsx# Dynamic action button
    │   │   ├── DisplayCampaigns.jsx # Grid grid wrapper for campaign cards
    │   │   ├── FormField.jsx   # Controlled input & textarea component
    │   │   ├── FundCard.jsx    # Individual campaign card component
    │   │   ├── Loader.jsx      # Transaction confirmation overlay
    │   │   ├── Navbar.jsx      # Top navigation with wallet connect & search
    │   │   └── Sidebar.jsx     # Sticky desktop navigation bar
    │   ├── constants/          # Static links, assets list, and navigation data
    │   ├── context/
    │   │   └── index.jsx       # StateContextProvider (Centralized Web3 state & hooks)
    │   ├── pages/
    │   │   ├── CampaignDetails.jsx # Detailed view, story, backer list & funding form
    │   │   ├── CreateCampaign.jsx   # New campaign submission form
    │   │   ├── Home.jsx             # All active campaigns view
    │   │   └── Profile.jsx          # User-specific campaign management view
    │   ├── utils/              # Helper utilities (date math, percentage bar, image validation)
    │   ├── App.jsx             # Primary route definitions & sidebar layout wrapper
    │   ├── index.css           # Tailwind directives & global styling overrides
    │   └── main.jsx            # Entry point wrapping App with ThirdwebProvider & Router
    ├── tailwind.config.js      # Custom themes, colors, and font definitions
    └── package.json
```

---

## 📜 Smart Contract Specification

The core contract (`Crowdfunding.sol`) handles project registration, donation tracking, and ETH transfer mechanics:

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Crowdfunding {
    struct Campaign {
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        address[] donators;
        uint256[] donations;
    }

    mapping(uint256 => Campaign) public campaigns;
    uint256 public numberOfCampaigns = 0;

    function createCampaign(
        address _owner,
        string memory _title,
        string memory _description,
        uint256 _target,
        uint256 _deadline,
        string memory _image
    ) public returns (uint256) {
        Campaign storage campaign = campaigns[numberOfCampaigns];

        require(campaign.deadline < block.timestamp, "The deadline should be a date in the future.");

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;

        numberOfCampaigns++;
        return numberOfCampaigns - 1;
    }

    function donateToCampaign(uint256 _id) public payable {
        uint256 amount = msg.value;
        Campaign storage campaign = campaigns[_id];

        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);

        (bool sent, ) = payable(campaign.owner).call{value: amount}("");

        if (sent) {
            campaign.amountCollected = campaign.amountCollected + amount;
        }
    }

    function getDonators(uint256 _id) public view returns (address[] memory, uint256[] memory) {
        return (campaigns[_id].donators, campaigns[_id].donations);
    }

    function getCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);

        for (uint i = 0; i < numberOfCampaigns; i++) {
            Campaign storage item = campaigns[i];
            allCampaigns[i] = item;
        }

        return allCampaigns;
    }
}
```

---

## ⚙️ Prerequisites

Before running the project locally, ensure you have the following installed:

- [Node.js](https://nodejs.org/) (`v16.0.0` or higher)
- [npm](https://www.npmjs.com/) or [yarn](https://yarnpkg.com/)
- [MetaMask Wallet](https://metamask.io/) browser extension initialized with testnet funds (e.g., Sepolia ETH via a testnet faucet).

---

## 📥 Installation & Setup

### 1. Clone the Repository
```bash
git clone https://github.com/your-username/web3-crowdfunding-platform.git
cd web3-crowdfunding-platform
```

### 2. Configure & Deploy Smart Contract (`web3/`)
```bash
cd web3
npm install
```

Create a `.env` file inside the `web3/` directory:
```env
PRIVATE_KEY=your_metamask_account_private_key
```

Deploy the contract to the testnet via Thirdweb CLI:
```bash
npm run deploy
```
*After deployment, copy the contract address provided in the Thirdweb Dashboard.*

### 3. Configure & Run Client Application (`client/`)
```bash
cd ../client
npm install
```

In `client/src/context/index.jsx`, update the contract address variable with your newly deployed smart contract address:
```javascript
const { contract } = useContract('YOUR_DEPLOYED_CONTRACT_ADDRESS');
```

Start the Vite development server:
```bash
npm run dev
```

Open your browser and navigate to `http://localhost:5173`.

---

## 🚀 Usage Guide

1. **Connect Wallet**: Click the **Connect** button in the top navigation bar to link your MetaMask extension. Ensure you are connected to the correct network (e.g., Sepolia).
2. **Explore Campaigns**: Browse all published campaigns on the Home page. Click any card to view detailed stories, deadlines, progress, and backer activity.
3. **Fund a Campaign**: On a campaign details page, enter an ETH amount (e.g., `0.05`), click **Fund Campaign**, and confirm the transaction in your MetaMask wallet popup.
4. **Create a Campaign**: Click **Create a Campaign**, fill out the project details (Title, Story, Goal Target in ETH, Deadline Date, Image URL), and submit. Confirm the gas transaction to publish your contract logic on-chain.
5. **View Your Portfolio**: Navigate to the **Profile** section to inspect campaigns created exclusively by your address.

---

## 🌐 Deployment

### Frontend (Netlify / Vercel)
To build the client application for production deployment:
```bash
cd client
npm run build
```
This generates a production-ready `dist/` directory. Upload or link this folder directly to static hosting platforms like **Netlify** or **Vercel**.

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.
```

---

💡 Would you like to add automated test scripts for the smart contract, add additional fields to the `README.md` (such as a troubleshooting section), or update your portfolio repository description?
