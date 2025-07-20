# ElectionX 🗳️

A decentralized voting app built with Flutter and Solidity, featuring a secure and transparent election system.

---

## 🚀 Project Overview

**ElectionX** enables users to participate in tamper-proof voting through a mobile interface powered by blockchain smart contracts. Voters cast their vote using a connected wallet, and only the designated owner can add candidates and view results after voting ends. The system guarantees vote integrity and privacy by leveraging the decentralized nature of Ethereum.

---

## 🛠️ Tech Stack & Key Features

- **Smart Contracts (Solidity)**
  - `Elections.sol`: Manages candidates, voting logic, and result computation
  - Includes `onlyOwner` and `votingOpen` modifiers
  - Automatically calculates the winner after the set voting duration
- **Front-end (Flutter/Dart)**
  - Cross-platform support (iOS, Android, Web, Desktop)
  - Connects to Ethereum wallets for voting and candidate actions
- **Wallet Integration / Web3**
  - Enables users to connect wallets and authenticate their votes
- **Time-bound Voting**
  - Voting closes automatically based on the duration set in the contract
- **Candidate Management**
  - Only the contract owner can register candidates

---

## 🧩 Role & Responsibilities

As the **Blockchain & Mobile Developer**, I:
- Implemented the Solidity smart contract for elections
- Developed the Flutter interface to interact with the contract
- Integrated wallet connectivity and transaction handling
- Tested the end-to-end voting flow and result display logic

---

## 🎯 Getting Started

Cloning the project:
```bash
git clone https://github.com/fadyefat/electionx.git
cd electionx
