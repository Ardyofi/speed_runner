import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(SpeedRunnerApp());
}

class SpeedRunnerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Speed Runner',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: GameScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late AnimationController _playerController;
  late AnimationController _backgroundController;
  late AnimationController _coinController;
  
  double playerY = 0.0;
  double playerVelocity = 0.0;
  double gravity = 800.0;
  double jumpForce = -400.0;
  bool isGrounded = true;
  bool gameStarted = false;
  bool gameOver = false;
  
  int score = 0;
  double gameSpeed = 200.0;
  
  List<Obstacle> obstacles = [];
  List<Coin> coins = [];
  
  Timer? gameTimer;
  Random random = Random();
  
  @override
  void initState() {
    super.initState();
    _playerController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    _backgroundController = AnimationController(
      duration: Duration(seconds: 10),
      vsync: this,
    )..repeat();
    _coinController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();
    
    resetGame();
  }
  
  void startGame() {
    setState(() {
      gameStarted = true;
      gameOver = false;
    });
    
    gameTimer = Timer.periodic(Duration(milliseconds: 16), (timer) {
      updateGame();
    });
  }
  
  void updateGame() {
    if (gameOver) return;
    
    setState(() {
      // Update player physics
      if (!isGrounded) {
        playerVelocity += gravity * 0.016;
        playerY += playerVelocity * 0.016;
        
        if (playerY >= 0) {
          playerY = 0;
          playerVelocity = 0;
          isGrounded = true;
        }
      }
      
      // Move obstacles and coins
      for (int i = obstacles.length - 1; i >= 0; i--) {
        obstacles[i].x -= gameSpeed * 0.016;
        if (obstacles[i].x < -50) {
          obstacles.removeAt(i);
        }
      }
      
      for (int i = coins.length - 1; i >= 0; i--) {
        coins[i].x -= gameSpeed * 0.016;
        if (coins[i].x < -30) {
          coins.removeAt(i);
        }
      }
      
      // Spawn new obstacles and coins
      if (obstacles.isEmpty || obstacles.last.x < 200) {
        spawnObstacle();
      }
      
      if (coins.isEmpty || coins.last.x < 150) {
        spawnCoin();
      }
      
      // Check collisions
      checkCollisions();
      
      // Increase game speed over time
      gameSpeed += 0.1;
      score += 1;
    });
  }
  
  void spawnObstacle() {
    double x = MediaQuery.of(context).size.width;
    obstacles.add(Obstacle(x: x, y: 0, width: 30, height: 60));
  }
  
  void spawnCoin() {
    double x = MediaQuery.of(context).size.width + random.nextDouble() * 100;
    double y = -random.nextDouble() * 80 - 30;  // Reduced from 100 to 80, and from 50 to 30
    coins.add(Coin(x: x, y: y));
  }
  
  void checkCollisions() {
    // Check obstacle collisions
    for (Obstacle obstacle in obstacles) {
      if (obstacle.x < 80 && obstacle.x > 20 && playerY > -obstacle.height + 20) {
        endGame();
        return;
      }
    }
    
    // Check coin collisions
    for (int i = coins.length - 1; i >= 0; i--) {
      Coin coin = coins[i];
      if (coin.x < 80 && coin.x > 20 && 
          playerY <= coin.y + 15 && playerY >= coin.y - 15) {
        coins.removeAt(i);
        score += 50;
      }
    }
  }
  
  void jump() {
    if (isGrounded && gameStarted && !gameOver) {
      setState(() {
        playerVelocity = jumpForce;
        isGrounded = false;
      });
      _playerController.forward().then((_) => _playerController.reverse());
    }
  }
  
  void endGame() {
    setState(() {
      gameOver = true;
    });
    gameTimer?.cancel();
  }
  
  void resetGame() {
    setState(() {
      playerY = 0.0;
      playerVelocity = 0.0;
      isGrounded = true;
      gameStarted = false;
      gameOver = false;
      score = 0;
      gameSpeed = 200.0;
      obstacles.clear();
      coins.clear();
    });
    gameTimer?.cancel();
  }
  
  @override
  void dispose() {
    _playerController.dispose();
    _backgroundController.dispose();
    _coinController.dispose();
    gameTimer?.cancel();
    super.dispose();
  }
  
  Widget _buildCloud(double size) {
    return Container(
      width: size,
      height: size * 0.6,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            bottom: 0,
            child: Container(
              width: size * 0.6,
              height: size * 0.4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: size * 0.3,
            bottom: 0,
            child: Container(
              width: size * 0.7,
              height: size * 0.5,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: size * 0.15,
            bottom: size * 0.2,
            child: Container(
              width: size * 0.4,
              height: size * 0.3,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: gameStarted ? jump : startGame,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF87CEEB), // Sky blue
                Color(0xFFE0F6FF), // Light blue
                Color(0xFFFFF8DC), // Cream
              ],
            ),
          ),
          child: Stack(
            children: [
              // Background clouds
              AnimatedBuilder(
                animation: _backgroundController,
                builder: (context, child) {
                  return Stack(
                    children: [
                      // Clouds
                      Positioned(
                        left: -_backgroundController.value * 100 + 50,
                        top: 80,
                        child: _buildCloud(60),
                      ),
                      Positioned(
                        left: -_backgroundController.value * 150 + 200,
                        top: 120,
                        child: _buildCloud(80),
                      ),
                      Positioned(
                        left: -_backgroundController.value * 80 + 350,
                        top: 60,
                        child: _buildCloud(50),
                      ),
                    ],
                  );
                },
              ),
              
              // Background elements
              AnimatedBuilder(
                animation: _backgroundController,
                builder: (context, child) {
                  return Positioned(
                    left: -_backgroundController.value * 200 - 100,
                    bottom: 50,
                    child: Row(
                      children: List.generate(10, (index) => 
                        Container(
                          width: 80,
                          height: 30,
                          margin: EdgeInsets.only(right: 60),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.green[400]!, Colors.green[600]!],
                            ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green[800]!.withOpacity(0.3),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Container(
                                  width: 8,
                                  height: 15,
                                  decoration: BoxDecoration(
                                    color: Colors.green[700],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                Container(
                                  width: 8,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.green[700],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                Container(
                                  width: 8,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: Colors.green[700],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              // Ground
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 50,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.brown[400]!, Colors.brown[700]!],
                    ),
                  ),
                  child: Row(
                    children: List.generate((MediaQuery.of(context).size.width / 20).ceil(), (index) =>
                      Container(
                        width: 20,
                        height: 50,
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(color: Colors.brown[800]!, width: 1),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(height: 10, color: Colors.green[700]),
                            Expanded(child: Container()),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Player
              Positioned(
                left: 50,
                bottom: 50 - playerY,
                child: AnimatedBuilder(
                  animation: _playerController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + _playerController.value * 0.1,
                      child: Container(
                        width: 40,
                        height: 40,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Character body
                            Container(
                              width: 35,
                              height: 35,
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  colors: [Colors.blue[300]!, Colors.blue[600]!],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue[900]!.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: Offset(2, 2),
                                  ),
                                ],
                              ),
                            ),
                            // Character face
                            Positioned(
                              top: 8,
                              child: Container(
                                width: 25,
                                height: 20,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    // Eyes
                                    Container(
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    Container(
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Running effect
                            if (!isGrounded)
                              Positioned(
                                bottom: -5,
                                child: Container(
                                  width: 20,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Obstacles
              ...obstacles.map((obstacle) => Positioned(
                left: obstacle.x,
                bottom: 50 + obstacle.y,
                child: Container(
                  width: obstacle.width,
                  height: obstacle.height,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Spike body
                      Container(
                        width: obstacle.width,
                        height: obstacle.height,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.grey[600]!, Colors.grey[800]!],
                          ),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                      // Spikes on top
                      Positioned(
                        top: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(3, (index) =>
                            Container(
                              width: 0,
                              height: 0,
                              decoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(width: 4, color: Colors.transparent),
                                  right: BorderSide(width: 4, color: Colors.transparent),
                                  bottom: BorderSide(width: 8, color: Colors.red[700]!),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Warning symbol
                      Icon(
                        Icons.warning_rounded,
                        color: Colors.yellow[600],
                        size: 20,
                      ),
                    ],
                  ),
                ),
              )),
              
              // Coins
              ...coins.map((coin) => Positioned(
                left: coin.x,
                bottom: 50 - coin.y,
                child: AnimatedBuilder(
                  animation: _coinController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _coinController.value * 2 * 3.14159,
                      child: Container(
                        width: 25,
                        height: 25,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer glow
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.yellow[300]!.withOpacity(0.6),
                                    Colors.transparent,
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                            ),
                            // Coin body
                            Container(
                              width: 25,
                              height: 25,
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  colors: [Colors.yellow[400]!, Colors.amber[600]!],
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.orange[700]!, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange[900]!.withOpacity(0.4),
                                    blurRadius: 4,
                                    offset: Offset(1, 1),
                                  ),
                                ],
                              ),
                            ),
                            // Coin details
                            Container(
                              width: 15,
                              height: 15,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.orange[800]!, width: 1),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '★',
                                  style: TextStyle(
                                    color: Colors.orange[800],
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )),
              
              // Score
              Positioned(
                top: 50,
                right: 20,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple[600]!, Colors.purple[800]!],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple[900]!.withOpacity(0.3),
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.stars,
                        color: Colors.yellow[300],
                        size: 20,
                      ),
                      SizedBox(width: 5),
                      Text(
                        '$score',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Start/Game Over screen
              if (!gameStarted || gameOver)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.purple[900]!.withOpacity(0.9),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue[400]!, Colors.purple[600]!],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Text(
                            gameOver ? '💥 Game Over!' : '🏃‍♂️ Speed Runner',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 4,
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        if (gameOver)
                          Container(
                            padding: EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.yellow[600],
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 5,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              '⭐ Final Score: $score',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        SizedBox(height: 20),
                        if (gameOver) ...[
                          SizedBox(height: 20),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[600],
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            onPressed: resetGame,
                            child: Text(
                              '🔄 Reset Game',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class Obstacle {
  double x;
  double y;
  double width;
  double height;
  
  Obstacle({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}

class Coin {
  double x;
  double y;
  
  Coin({required this.x, required this.y});
}