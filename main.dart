
import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:js_util' as js_util;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Token Wallet',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String walletAddress = 'Not Connected';
  String ethBalance = '0';
  String recipientAddress = '';
  String sendAmount = '';
  String transactionStatus = '';

  String tokenContractAddress = '';
  String tokenRecipientAddress = '';
  String tokenAmount = '';
  String tokenTransactionStatus = '';

  Future<void> connectWallet() async {
    try {
      final address = await js_util.promiseToFuture<String?>(
        js_util.callMethod(html.window, 'connectToMetaMask', []),
      );

      if (address != null) {
        setState(() => walletAddress = address);
        await fetchBalance(address);
      } else {
        setState(() {
          walletAddress = 'Connection Failed';
          ethBalance = '0';
        });
      }
    } catch (error) {
      print('Connect Wallet Error: \$error');
      setState(() {
        walletAddress = 'Error connecting wallet';
        ethBalance = '0';
      });
    }
  }

  Future<void> fetchBalance(String address) async {
    try {
      final balance = await js_util.promiseToFuture<String?>(
        js_util.callMethod(html.window, 'getETHBalance', [address]),
      );
      setState(() {
        ethBalance = balance ?? '0';
      });
    } catch (error) {
      print('Balance Error: \$error');
      setState(() {
        ethBalance = 'Failed to fetch balance';
      });
    }
  }

  Future<void> sendETH() async {
    if (recipientAddress.isEmpty || sendAmount.isEmpty) {
      setState(() => transactionStatus = 'Fill recipient & amount!');
      return;
    }

    try {
      final txHashes = await js_util.promiseToFuture<String?>(
        js_util.callMethod(html.window, 'sendETH', [recipientAddress, sendAmount]),
      );
      setState(() {
        transactionStatus = txHashes != null ? 'Success! \$txHashes' : 'Failed!';
      });
      if (txHashes != null) await fetchBalance(walletAddress);
    } catch (error) {
      print('ETH Send Error: \$error');
      setState(() => transactionStatus = 'Error sending ETH');
    }
  }

  Future<void> sendToken() async {
    if (tokenContractAddress.isEmpty || tokenRecipientAddress.isEmpty || tokenAmount.isEmpty) {
      setState(() => tokenTransactionStatus = 'Fill all token fields!');
      return;
    }

    try {
      final txHashes = await js_util.promiseToFuture<String?>(
        js_util.callMethod(html.window, 'sendERC20Token', [
          tokenContractAddress,
          tokenRecipientAddress,
          tokenAmount
        ]),
      );
      setState(() {
        tokenTransactionStatus = txHashes != null ? 'Token Success! \$txHashes' : 'Token Failed!';
      });
    } catch (error) {
      print('Token Send Error: \$error');
      setState(() => tokenTransactionStatus = 'Error sending token');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Token Wallet')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Text('Wallet Address:', style: TextStyle(fontSize: 18)),
                Text(walletAddress, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.blue)),
                const SizedBox(height: 20),
                const Text('ETH Balance:', style: TextStyle(fontSize: 18)),
                Text('\$ethBalance ETH', style: const TextStyle(fontSize: 16, color: Colors.green)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(onPressed: connectWallet, child: const Text('Connect Wallet')),
                    const SizedBox(width: 10),
                    ElevatedButton(onPressed: () => fetchBalance(walletAddress), child: const Text('Refresh Balance')),
                  ],
                ),
                const Divider(height: 40),
                const Text('Send ETH', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextField(decoration: const InputDecoration(labelText: 'Recipient Address'), onChanged: (val) => recipientAddress = val),
                TextField(decoration: const InputDecoration(labelText: 'Amount (ETH)'), keyboardType: TextInputType.number, onChanged: (val) => sendAmount = val),
                ElevatedButton(onPressed: sendETH, child: const Text('Send ETH')),
                Text(transactionStatus, style: const TextStyle(color: Colors.orange)),
                const Divider(height: 40),
                const Text('Send ERC-20 Token', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextField(decoration: const InputDecoration(labelText: 'Token Contract Address'), onChanged: (val) => tokenContractAddress = val),
                TextField(decoration: const InputDecoration(labelText: 'Recipient Address'), onChanged: (val) => tokenRecipientAddress = val),
                TextField(decoration: const InputDecoration(labelText: 'Amount (Token)'), keyboardType: TextInputType.number, onChanged: (val) => tokenAmount = val),
                ElevatedButton(onPressed: sendToken, child: const Text('Send Token')),
                Text(tokenTransactionStatus, style: const TextStyle(color: Colors.purple)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
