// Basic Types and Setup
type CharacterClass = "Ranger" | "Mage" | "Rogue";
type CharacterID = string | number;

// xEnum. Note, prefer union types
enum Rarity {
  Common,
  Uncommon,
  Rare,
  Legendary,
}

// xUnionType: Union Types
type Action = "attack" | "defend" | "heal";

// xString: String Handling and Methods
const equipment = "Sword,Shield,Armor".split(","); // ["Sword", "Shield", "Armor"]
const nameRegex = /^[A-Za-z]+$/;
const characterGreeting = "Welcome, brave ranger!  ";
characterGreeting.toUpperCase(); // "WELCOME, BRAVE RANGER!  "
characterGreeting.includes("ranger"); // true
characterGreeting.startsWith("Welcome"); // true
characterGreeting.replace("ranger", "hero"); // "Welcome, brave hero!  "
characterGreeting.trim(); // "Welcome, brave ranger!"

// xArray: Array Handling and Methods
const characterNames = ["Aragorn", "Gandalf"];
const defaultHealth: number[] = Array(3).fill(100); // [100, 100, 100]
for (const characterName of characterNames) characterName; // "Aragorn", "Gandalf"
const characterNamesUpper = characterNames.map((name) => name.toUpperCase()); // ["ARAGORN", "GANDALF"]
const totalHealth = characterNames.reduce(
  (total, name) => total + name.length,
  0
); // 13 (length of "Aragorn" + "Gandalf")
const mageCharacter = characterNames.find((name) => name === "Gandalf"); // "Gandalf"
const isAnyCharacterInjured = characterNames.some((name) => name.length > 5); // true
const areAllCharactersHealthy = characterNames.every((name) => name.length > 5); // true
const removedCharacter = characterNames.splice(1, 1); // ["Gandalf"]
const moreCharacters = ["Legolas"];
const allCharacters = characterNames.concat(moreCharacters); // ["Aragorn", "Legolas"]

// x2D: 2D Array
const gameMap: number[][] = [
  [0, 1, 0],
  [0, 0, 1],
  [1, 0, 0],
];
const randomPosition = (): [number, number] => [
  Math.floor(Math.random() * gameMap.length),
  Math.floor(Math.random() * gameMap[0].length),
];

// xTypeAssertion: Type Assertions
let unknownCharacterData: unknown = "Gandalf the Grey";
let characterNameLength: number = (unknownCharacterData as string).length; // 16

// xSpread: Spread Syntax
const characterInfo = { name: "Aragorn", class: "Ranger", health: 100 };
const updatedCharacterInfo = { ...characterInfo, level: 5 }; // { name: "Aragorn", class: "Ranger", health: 100, level: 5 }

// xDestructuring: Destructuring
const {
  name: characterNameDestructured,
  class: classType,
  health,
} = characterInfo; // characterNameDestructured: "Aragorn", classType: "Ranger"

// xOptionalProp
interface CharacterStats {
  health: number;
  mana?: number;
}
const stats: CharacterStats = { health: 100 }; // Mana can be omitted

// xNullishCoalescing: ?? Operator
const mana = stats.mana ?? 50; // 50 (since mana is undefined)

// xSwitchStatement: Switch Statement
function handleAction(action: Action) {
  switch (action) {
    case "attack":
    case "defend": // Fallthrough
      console.log("Preparing for combat!");
      break;
    case "heal":
      console.log("Healing!");
      break;
    default:
      console.log("Unknown action.");
  }
}
handleAction("attack"); // "Preparing for combat!"

// xArrowFunction: Arrow Function
const calculateDamage = (attack: number, defense: number): number =>
  attack - defense > 0 ? attack - defense : 0;

// xAnonymousFunction: Anonymous Function
const healCharacter = function (
  health: number,
  potionStrength: number
): number {
  return health + potionStrength;
};

// xMovable: Interface and Class
interface Movable {
  position: [number, number];
  move: (dx: number, dy: number) => void;
}
class Character implements Movable {
  readonly weapon: string;
  constructor(
    public id: CharacterID,
    public name: string,
    public classType: CharacterClass,
    public position: [number, number] = [0, 0],
    public health: number = 100,
    weapon: string = "Sword"
  ) {
    this.weapon = weapon;
  }
  move(dx: number, dy: number) {
    this.position[0] += dx;
    this.position[1] += dy;
  }
}
const aragorn = new Character(1, "Aragorn", "Ranger");

// xSort: Sorting and Filtering
const characters: Character[] = [aragorn, new Character(2, "Gandalf", "Mage")];
characters.sort((a, b) => a.classType.localeCompare(b.classType)); // Sorted alphabetically by classType
const healthyCharacters = characters.filter((char) => char.health > 50); // Only characters with health > 50
const healthStatus =
  healthyCharacters.length > 0
    ? "Healthy characters found"
    : "No healthy characters";

// xSet
const uniqueClasses = new Set<CharacterClass>(["Ranger", "Mage"]);
uniqueClasses.add(aragorn.classType); // {"Ranger", "Mage"}
const secondSet = new Set<CharacterClass>(["Mage", "Rogue"]);
const intersection = new Set(
  [...uniqueClasses].filter((cls) => secondSet.has(cls))
); // Intersection: {"Mage"}
const union = new Set([...uniqueClasses, ...secondSet]); // Union: {"Ranger", "Mage", "Rogue"}

// xMap: Map
const characterMap: Map<CharacterID, Character> = new Map();
characterMap.set(aragorn.id, aragorn); // Adds aragorn to the map
characterMap.has(1); // true
// Iterating through a Map’s keys and values
for (const [id, character] of characterMap) {
  console.log(`ID: ${id}, Name: ${character.name}`);
} // ID: 1, Name: Aragorn

// xIndexSignature: Index Signature
interface InventoryCount {
  [itemName: string]: number; // The keys are dynamic strings
}
const inventoryCount: InventoryCount = { sword: 1, shield: 2 };

// xGenerics: Generics
function filterInventory<T>(items: T[], condition: (item: T) => boolean): T[] {
  return items.filter(condition);
}
// Convert InventoryCount object into an array for filtering
const inventoryEntries = Object.entries(inventoryCount); // [["sword", 1], ["shield", 2]]
const rareItems = filterInventory(
  inventoryEntries,
  ([, quantity]) => quantity > 1
); // [["shield", 2]]

// xHeap: Priority Queue
class PriorityQueue<T> {
  private heap: { value: T; priority: number }[] = [];
  enqueue(value: T, priority: number): void {
    this.heap.push({ value, priority });
    this.heap.sort((a, b) => b.priority - a.priority);
  }
  dequeue(): T | undefined {
    return this.heap.shift()?.value;
  }
}
const taskQueue = new PriorityQueue<string>();
taskQueue.enqueue("Defend Village", 2);
taskQueue.enqueue("Attack Orcs", 1);

// xTree: Binary Search Tree
type Item = { name: string; rarity: Rarity };
class BSTNode<T> {
  left: BSTNode<T> | null = null;
  right: BSTNode<T> | null = null;
  constructor(public value: T) {}
}
class Inventory {
  root: BSTNode<Item> | null = null;
  insert(item: Item) {
    const insertNode = (
      node: BSTNode<Item> | null,
      value: Item
    ): BSTNode<Item> => {
      if (node === null) return new BSTNode(value);
      return value.name < node.value.name
        ? (node.left = insertNode(node.left, value))
        : (node.right = insertNode(node.right, value));
    };
    this.root = insertNode(this.root, item);
  }
  traverseInOrder(
    callback: (node: BSTNode<Item>) => void,
    node: BSTNode<Item> | null = this.root
  ): void {
    if (node === null) return;
    this.traverseInOrder(callback, node.left);
    callback(node);
    this.traverseInOrder(callback, node.right);
  }
  searchItem(name: string): Item | null {
    const searchNode = (
      node: BSTNode<Item> | null,
      name: string
    ): BSTNode<Item> | null => {
      if (node === null) return null;
      return name === node.value.name
        ? node
        : name < node.value.name
        ? searchNode(node.left, name)
        : searchNode(node.right, name);
    };
    return searchNode(this.root, name)?.value || null;
  }
}

// xTypes: Intersection Types
interface WithHealth {
  health: number;
}
interface WithMana {
  mana: number;
}
type Mage = WithHealth & WithMana;

// xTypeGuard: Type Guards
function isMage(character: any): character is Mage {
  return (character as Mage).mana !== undefined;
}
const gandalf: WithHealth & WithMana = { health: 100, mana: 200 };
if (isMage(gandalf)) {
  console.log(`${gandalf.health} health and ${gandalf.mana} mana`); // TypeScript knows gandalf has mana
}

// xUtilityTypes: Utility Types
type PartialCharacter = Partial<Character>;
const partialAragorn: PartialCharacter = { health: 80 }; // Only some properties are defined

// xFunctionOverloading: Function Overloading
function getItemDetails(name: string): string;
function getItemDetails(id: number): string;
function getItemDetails(value: string | number): string {
  return typeof value === "string" ? `Item: ${value}` : `Item ID: ${value}`;
}

// xAsync: Async Operation
async function loadGameData(url: string): Promise<void> {
  const response = await fetch(url);
  if (!response.ok) throw new Error("Failed to load game data");
  console.log(await response.json());
}
