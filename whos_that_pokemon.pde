import processing.sound.*;
import http.requests.*;

//declaring global objects
Pokemon pokemon;
PImage pokemonBG;
PFont pokemonTitle, pokemonText;
SoundFile whosThatPokemon;

void setup() {
  //must be same size as background png
  size(1000,563);
  
  //loading assets
  pokemonBG = loadImage("whosthatpokemon.png");
  pokemonTitle = createFont("Pokemon Solid.ttf",56);
  pokemonText = createFont("Pokemon Solid.ttf",48);
  whosThatPokemon = new SoundFile(this, "whos-that-pokemon.mp3");
  resetGame();
  
   
}

//rolls a random pokemon number, makes API call,
//and creates Pokemon object with all data,
//including the Pokemon's picture
void resetGame() {
  int i = int(random(1, 721));
  
  String url = "https://pokeapi.co/api/v2/pokemon/" + i;
   
   //packages and sends data request
   GetRequest get = new GetRequest(url);
   get.send();
   
   //gets received content, packages as JSONObject
   JSONObject json = parseJSONObject(get.getContent());
   
   String name = json.getString("name");
   //covers mr mime and mime jr
   name = name.replace('-', ' ');
   int attack = json.getJSONArray("stats").getJSONObject(1).getInt("base_stat");
   int defense = json.getJSONArray("stats").getJSONObject(2).getInt("base_stat");
   int specialAttack = json.getJSONArray("stats").getJSONObject(3).getInt("base_stat");
   int specialDefense = json.getJSONArray("stats").getJSONObject(4).getInt("base_stat");
   int speed = json.getJSONArray("stats").getJSONObject(5).getInt("base_stat");
   String iconURL = json.getJSONObject("sprites").getString("front_default");
   PImage pokemonImage = loadImage(iconURL);
   SoundFile cry = new SoundFile(this, "cries/"+i+".mp3");
   
   
   pokemon = new Pokemon(name, attack, defense, specialAttack, specialDefense, speed, iconURL, pokemonImage, cry);
   whosThatPokemon.play();
   
   
   typing = "";
}

String typing = "";
boolean guessed = false;
boolean displayingEndMessage = false;
int score = 0;
int highScore = 0;
int plays = 0;
final int MAX_PLAYS = 3;
boolean gameOver = false;

void initializeGlobals() {
  score = 0;
  highScore = 0;
  plays = 0;
  guessed = false;
  displayingEndMessage = false;
  gameOver = false;
}

void draw() {
  background(pokemonBG);
  
  textAlign(CENTER, BOTTOM);
  outlinedPokemonText("Who\'s That Pokemon?", 300, 125, pokemonTitle);
  outlinedPokemonText("Score", 850, 100, pokemonText); 
  strokeWeight(8);
  stroke(0,0,255);
  line(780, 90, 920, 90);
  
  strokeWeight(4);
  stroke(255, 255, 0);
  line(780, 90, 920, 90);
  outlinedPokemonText("" + score, 845, 175, pokemonText); 
  if (!guessed) {
    //black tint
    tint(0,0,0,255);
    image(pokemon.getImage(), 100, 100, 400, 400);
  }
  else {
    //reveals Pokemon
    noTint();
    image(pokemon.getImage(), 100, 100, 400, 400);
    
    //gets Pokemon's name, uppercases first letter
    String pokemonName = pokemon.getName();
    pokemonName = pokemonName.substring(0, 1).toUpperCase() + pokemonName.substring(1);
    
    if (pokemonName.toLowerCase().equals(typing.toLowerCase())) {
        String s = "That's right, it's " + pokemonName + "!";
        outlinedPokemonText(s, width/2, 550,pokemonText);
        //ensures score only added once
        if (!displayingEndMessage) {
          score++;
          plays++;
          if (score > highScore) {
            highScore = score;
          }
        }
    }
    else {
      String s = "No, it's " + pokemonName + "!";
      outlinedPokemonText(s, width/2, 550,pokemonText);
      if (!displayingEndMessage) {
          score = 0;
          plays++; 
      }
    }
    
    try {
      pokemon.getCry().play();
    }
    catch(Exception e) {
     print("Error in accessing sound file."); 
    }
    
    //checks for if the end message is currently displaying
    //if it is displaying, wait for two seconds, then reset the game
    if (displayingEndMessage) {
       delay(2000);
      
      //reset game if MAX_PLAYS not reached
      //have to return so it draws the end-of-round msg
      if (plays < MAX_PLAYS) {
        guessed = false;
        displayingEndMessage = false;
        resetGame();
        return;
      }
      //game over screen
      //has to return so that draw() will display the frame
      else {
        gameOver = true;
        background(pokemonBG);
        outlinedPokemonText("High Score: " + highScore, 300, height/2, pokemonTitle);
        outlinedPokemonText("Press Enter to play again!", 325, height/2 + 100, pokemonText);
        noLoop();
        return;
      }
    }
    
    //sets displayingEndMessage to true here because draw()
    //won't write to the canvas until it is returned
    displayingEndMessage = true;
    return;
    
  }
  
  
  
  //keeping the display of "typing" here will make the text disappear 
  //when a win is detected, because of the return statement above
  textSize(24);
  outlinedPokemonText(typing, 300,500,pokemonText);
  
}

void keyPressed() {
   
  if (keyCode == 10) {
    //if game isn't over, set "guessed" flag to true to check
    //for if the response is a winner
    if (!gameOver) {
      guessed = true;
    }
    //otherwise, restarts game when Enter key pressed
    else { 
     loop();
     initializeGlobals();
     resetGame();
   }
  }
  //if pressing backspace, delete haracters
  else if (keyCode == 8) {
    if (typing.length() > 1) {
      typing = typing.substring(0, typing.length()-1);
    }
    //need this if only one character left
    else {
      typing = "";
    }
  }
  //typed character is added to string 'typing'
  else if ((keyCode > 64 && keyCode < 123) || keyCode == 32) {
    typing += key;
  }

}

void outlinedPokemonText(String s, int x, int y, PFont font) {
   //outline with hollow font
   textFont(font);
   fill(0, 128, 255);
   for (int i = -3; i < 4; i++) {
     text(s, x+i, y);
     text(s, x, y+i);
   }
   
   //solid yellow interior
   fill(255, 255, 0);
   text(s, x, y);
}


class Pokemon {
  private String name;
  private int attack;
  private int defense;
  private int specialAttack;
  private int specialDefense;
  private int speed;
  private String iconURL;
  private PImage pokemonImage;
  private SoundFile cry;
  
  public Pokemon(String name, int attack, int defense, int specialAttack, int specialDefense, int speed, String iconURL, PImage pokemonImage, SoundFile cry) {
    this.name = name;
    this.attack = attack;
    this.defense = defense;
    this.specialAttack = specialAttack;
    this.specialDefense = specialDefense;
    this.speed = speed;
    this.iconURL = iconURL;
    this.pokemonImage = pokemonImage;
    this.cry = cry;
  }
  
  public String getName() {
    return name;
  }
  
  public int getAttack() {
    return attack;
  }
  
  public int getDefense() {
    return defense;
  }
  
  public int getSpecialAttack() {
    return specialAttack;
  }
  
  public int getSpecialDefense() {
    return specialDefense;
  }
  
  public int getSpeed() {
    return speed;
  }
  
  public String getIconURL() {
    return iconURL;
  }
  
  public PImage getImage() {
    return pokemonImage;
  }
  
  public SoundFile getCry() {
     return cry; 
  }
    
}
