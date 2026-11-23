# Behavioral Patterns

Patterns concerned with algorithms and the assignment of responsibilities between objects.

---

## Observer

**Problem**: Multiple objects need to be notified about state changes in another object without tight coupling.

**When to Use**:
- Changes in one object require changing others, and the set of objects is dynamic or unknown
- GUI classes need to react to user actions
- Objects need to observe others temporarily or in specific cases

**Structure**:
- `Publisher` - Maintains subscriber list, notifies on state changes
- `Subscriber` - Interface with update method
- `ConcreteSubscriber` - Implements update to react to changes

**C++ Example**:
```
#include <iostream>
#include <vector>
#include <string>
#include <algorithm>

// Observer interface
class IObserver {
public:
    virtual ~IObserver() = default;
    virtual void update(const std::string& message) = 0;
};

// Subject interface
class ISubject {
public:
    virtual ~ISubject() = default;
    virtual void attach(IObserver* observer) = 0;
    virtual void detach(IObserver* observer) = 0;
    virtual void notify() = 0;
};

// Concrete subject
class NewsPublisher : public ISubject {
private:
    std::vector<IObserver*> observers_;
    std::string news_;

public:
    void attach(IObserver* observer) override {
        observers_.push_back(observer);
    }

    void detach(IObserver* observer) override {
        observers_.erase(
            std::remove(observers_.begin(), observers_.end(), observer),
            observers_.end()
        );
    }

    void notify() override {
        for (auto* observer : observers_) {
            observer->update(news_);
        }
    }

    void publishNews(const std::string& news) {
        news_ = news;
        std::cout << "\n[Publisher] Publishing news: " << news_ << "\n";
        notify();
    }
};

// Concrete observer - subscriber
class Subscriber : public IObserver {
private:
    std::string name_;

public:
    explicit Subscriber(std::string name) : name_(std::move(name)) {}

    void update(const std::string& message) override {
        std::cout << "[Subscriber " << name_
                  << "] received: " << message << "\n";
    }
};

int main() {
    NewsPublisher publisher;

    Subscriber alice("Alice");
    Subscriber bob("Bob");
    Subscriber charlie("Charlie");

    publisher.attach(&alice);
    publisher.attach(&bob);
    publisher.attach(&charlie);

    publisher.publishNews("Breaking: C++23 is here!");

    // Bob unsubscribes
    publisher.detach(&bob);
    publisher.publishNews("Update: New features announced");

    return 0;
}
```

**Pros**:
- Open/Closed - add new subscribers without modifying publisher
- Establish relationships at runtime

**Cons**:
- Subscribers notified in random order
- Can cause memory leaks if not unsubscribed

**Related**: Mediator (eliminates direct connections), Command/Chain of Responsibility (different sender-receiver relationships)

---

## Strategy

**Problem**: Multiple algorithm variants within a single class cause code bloat and make changes risky.

**When to Use**:
- Need to use different variants of an algorithm and switch at runtime
- Similar classes differ only in behavior execution
- Want to isolate business logic from implementation details
- Class has massive conditionals selecting between algorithms

**Structure**:
- `Context` - Maintains reference to strategy
- `Strategy` - Interface for algorithms
- `ConcreteStrategy` - Implements specific algorithm

**C++ Example**:
```
#include <iostream>
#include <memory>
#include <vector>
#include <string>

// Strategy interface
class ISortStrategy {
public:
    virtual ~ISortStrategy() = default;
    virtual void sort(std::vector<int>& data) const = 0;
    virtual std::string name() const = 0;
};

// Concrete strategies
class BubbleSort : public ISortStrategy {
public:
    void sort(std::vector<int>& data) const override {
        for (size_t i = 0; i < data.size(); ++i)
            for (size_t j = 0; j + 1 < data.size() - i; ++j)
                if (data[j] > data[j + 1])
                    std::swap(data[j], data[j + 1]);
    }
    std::string name() const override { return "BubbleSort"; }
};

class SelectionSort : public ISortStrategy {
public:
    void sort(std::vector<int>& data) const override {
        for (size_t i = 0; i < data.size(); ++i) {
            size_t min = i;
            for (size_t j = i + 1; j < data.size(); ++j)
                if (data[j] < data[min]) min = j;
            std::swap(data[i], data[min]);
        }
    }
    std::string name() const override { return "SelectionSort"; }
};

class StdSort : public ISortStrategy {
public:
    void sort(std::vector<int>& data) const override {
        std::sort(data.begin(), data.end());
    }
    std::string name() const override { return "StdSort"; }
};

// Context - uses a strategy
class Sorter {
private:
    std::unique_ptr<ISortStrategy> strategy_;

public:
    explicit Sorter(std::unique_ptr<ISortStrategy> strategy)
        : strategy_(std::move(strategy)) {}

    void setStrategy(std::unique_ptr<ISortStrategy> strategy) {
        strategy_ = std::move(strategy);
    }

    void run(std::vector<int> data) const {
        strategy_->sort(data);
        std::cout << strategy_->name() << ": ";
        for (int x : data) std::cout << x << " ";
        std::cout << "\n";
    }
};

int main() {
    std::vector<int> data = {5, 2, 8, 1, 9, 3};

    Sorter sorter(std::make_unique<BubbleSort>());
    sorter.run(data);

    sorter.setStrategy(std::make_unique<SelectionSort>());
    sorter.run(data);

    sorter.setStrategy(std::make_unique<StdSort>());
    sorter.run(data);

    return 0;
}
```

**Pros**:
- Swap algorithms at runtime
- Isolate implementation from usage
- Use composition instead of inheritance
- Open/Closed - add new strategies without changing context

**Cons**:
- Overkill for few rarely-changing algorithms
- Clients must understand strategy differences
- Modern functional programming may reduce need

**Related**: Command (turns operations to objects), State (strategies may be aware of each other), Template Method (class-level vs object-level)

---

## Command

**Problem**: Tight coupling between GUI elements and business logic makes code difficult to reuse and extend.

**When to Use**:
- Parameterize objects with operations
- Queue, schedule, or execute operations remotely
- Implement reversible operations (undo/redo)
- Want to log or persist operations

**Structure**:
- `Command` - Interface with execute method
- `ConcreteCommand` - Implements execute, stores receiver and parameters
- `Invoker` - Triggers commands
- `Receiver` - Contains business logic

**C++ Example**:
```
#include <iostream>
#include <memory>
#include <vector>
#include <string>

// Command interface
class ICommand {
public:
    virtual ~ICommand() = default;
    virtual void execute() = 0;
    virtual void undo() = 0;
};

// Receiver - the object that actually does the work
class Light {
    std::string name_;
public:
    explicit Light(std::string name) : name_(std::move(name)) {}

    void on()  { std::cout << name_ << " light is ON\n"; }
    void off() { std::cout << name_ << " light is OFF\n"; }
};

// Concrete commands
class LightOnCommand : public ICommand {
    Light& light_;
public:
    explicit LightOnCommand(Light& light) : light_(light) {}
    void execute() override { light_.on(); }
    void undo()    override { light_.off(); }
};

class LightOffCommand : public ICommand {
    Light& light_;
public:
    explicit LightOffCommand(Light& light) : light_(light) {}
    void execute() override { light_.off(); }
    void undo()    override { light_.on(); }
};

// Invoker - triggers commands, keeps history for undo
class RemoteControl {
    std::vector<std::unique_ptr<ICommand>> history_;
public:
    void press(std::unique_ptr<ICommand> cmd) {
        cmd->execute();
        history_.push_back(std::move(cmd));
    }

    void undoLast() {
        if (history_.empty()) {
            std::cout << "Nothing to undo\n";
            return;
        }
        history_.back()->undo();
        history_.pop_back();
    }
};

int main() {
    Light livingRoom("Living room");

    RemoteControl remote;
    remote.press(std::make_unique<LightOnCommand>(livingRoom));
    remote.press(std::make_unique<LightOffCommand>(livingRoom));

    std::cout << "-- undo --\n";
    remote.undoLast();   // turns light back ON
    remote.undoLast();   // turns light back OFF

    return 0;
}
```

**Pros**:
- Decouples invokers from performers (Single Responsibility)
- Open/Closed - new commands without modifying existing code
- Implements undo/redo
- Supports deferred execution
- Compose simple commands into complex ones

**Cons**:
- Adds new layer between senders and receivers

**Related**: Chain of Responsibility/Mediator/Observer (sender-receiver patterns), Memento (undo state), Strategy (operation to object)

---

## State

**Problem**: Objects behave differently based on state, leading to massive conditionals that are hard to maintain.

**When to Use**:
- Object behavior depends on state with numerous states and frequent changes
- Class has bulky conditionals altering behavior based on field values
- Similar states have duplicate code in state machine

**Structure**:
- `Context` - Maintains current state, delegates requests
- `State` - Interface declaring state-specific methods
- `ConcreteState` - Implements behavior for specific state

**C++ Example**:
```
#include <iostream>
#include <memory>
#include <string>

class Document;

// State interface
class IState {
public:
    virtual ~IState() = default;
    virtual void publish(Document& doc) = 0;
    virtual void printStatus() const = 0;
};

// Context
class Document {
    std::unique_ptr<IState> state_;
public:
    explicit Document(std::unique_ptr<IState> state);

    void setState(std::unique_ptr<IState> state) { state_ = std::move(state); }

    void publish() { state_->publish(*this); }
    void printStatus() const { state_->printStatus(); }
};

// Concrete states
class DraftState : public IState {
public:
    void publish(Document& doc) override;   // defined below
    void printStatus() const override {
        std::cout << "Status: Draft\n";
    }
};

class ModerationState : public IState {
public:
    void publish(Document& doc) override;   // defined below
    void printStatus() const override {
        std::cout << "Status: On moderation\n";
    }
};

class PublishedState : public IState {
public:
    void publish(Document& doc) override {
        std::cout << "Already published. Nothing to do.\n";
    }
    void printStatus() const override {
        std::cout << "Status: Published\n";
    }
};

// Document constructor
Document::Document(std::unique_ptr<IState> state) : state_(std::move(state)) {}

// Transitions (defined after all states are known)
void DraftState::publish(Document& doc) {
    std::cout << "Draft sent to moderation.\n";
    doc.setState(std::make_unique<ModerationState>());
}

void ModerationState::publish(Document& doc) {
    std::cout << "Moderation approved. Publishing.\n";
    doc.setState(std::make_unique<PublishedState>());
}

int main() {
    Document doc(std::make_unique<DraftState>());

    doc.printStatus();
    doc.publish();      // Draft -> Moderation

    doc.printStatus();
    doc.publish();      // Moderation -> Published

    doc.printStatus();
    doc.publish();      // Already published

    return 0;
}
```

**Pros**:
- Single Responsibility - organize state-related code
- Open/Closed - add new states without modifying existing
- Eliminates bulky conditionals

**Cons**:
- Overkill for simple state machines with few states

**Related**: Bridge/Strategy (structure), but State allows states to be aware of each other and change context state

---

## Template Method

**Problem**: Multiple classes implement similar algorithms with slight variations, causing code duplication.

**When to Use**:
- Let clients extend specific algorithm steps, not the whole structure
- Several classes contain nearly identical algorithms with minor differences
- Want to eliminate code duplication while preserving structure

**Structure**:
- `AbstractClass` - Defines template method and abstract steps
- `ConcreteClass` - Implements abstract steps

**C++ Example**:
```
// Abstract class
#include <iostream>
#include <string>

// Abstract base class - defines the algorithm skeleton
class DataMiner {
public:
    virtual ~DataMiner() = default;

    // Template method - the algorithm skeleton (non-virtual!)
    void mine(const std::string& path) {
        openFile(path);
        extractData();
        parseData();
        analyzeData();
        if (shouldSendReport()) {      // hook
            sendReport();
        }
        closeFile();
    }

protected:
    // Steps that subclasses MUST implement
    virtual void openFile(const std::string& path) = 0;
    virtual void extractData() = 0;
    virtual void parseData() = 0;

    // Steps with default behavior - subclasses MAY override
    virtual void analyzeData() {
        std::cout << "  Analyzing data (default)...\n";
    }

    virtual void sendReport() {
        std::cout << "  Sending report (default)...\n";
    }

    virtual void closeFile() {
        std::cout << "  Closing file (default)...\n";
    }

    // Hook - subclasses can override to control flow
    virtual bool shouldSendReport() const { return true; }
};

// Concrete implementation 1
class PDFMiner : public DataMiner {
protected:
    void openFile(const std::string& path) override {
        std::cout << "  Opening PDF: " << path << "\n";
    }
    void extractData() override {
        std::cout << "  Extracting text from PDF...\n";
    }
    void parseData() override {
        std::cout << "  Parsing PDF structure...\n";
    }
    void analyzeData() override {
        std::cout << "  Analyzing PDF content...\n";
    }
};

// Concrete implementation 2
class CSVMiner : public DataMiner {
protected:
    void openFile(const std::string& path) override {
        std::cout << "  Opening CSV: " << path << "\n";
    }
    void extractData() override {
        std::cout << "  Extracting rows from CSV...\n";
    }
    void parseData() override {
        std::cout << "  Parsing CSV columns...\n";
    }
    // Overrides the hook - no report for CSV
    bool shouldSendReport() const override { return false; }
};

int main() {
    std::cout << "=== PDF Miner ===\n";
    PDFMiner pdf;
    pdf.mine("report.pdf");

    std::cout << "\n=== CSV Miner ===\n";
    CSVMiner csv;
    csv.mine("data.csv");

    return 0;
}
```

**Pros**:
- Clients override only specific algorithm parts
- Pull duplicate code to superclass

**Cons**:
- Clients limited by provided skeleton
- Can violate Liskov Substitution Principle
- Harder to maintain with many steps

**Related**: Factory Method (specialization of Template Method), Strategy (uses composition and runtime switching vs inheritance)

**Note**: Template Method works at class level (static), Strategy at object level (dynamic runtime switching).

---

## Memento

**Problem**: Need to save and restore an object's previous state without breaking encapsulation or exposing internal details.

**When to Use**:
- Need to produce snapshots of object state to restore previous states
- Implement undo/redo functionality
- Handle transaction rollback on errors
- Direct access to object fields would violate encapsulation

**Structure**:
- `Originator` - Creates memento containing snapshot of its state
- `Memento` - Value object acting as snapshot of originator's state
- `Caretaker` - Knows when and why to save/restore originator state

**C++ Example**:
```
// Memento - stores snapshot
#include <iostream>
#include <string>
#include <vector>
#include <memory>

// Memento - stores a snapshot of the Originator's state
// Only the Originator may read/write its contents.
class EditorMemento {
private:
    friend class Editor;  // only Editor can access the state

    std::string text_;
    int cursor_;

    EditorMemento(std::string text, int cursor)
        : text_(std::move(text)), cursor_(cursor) {}
};

// Originator - the object whose state we save/restore
class Editor {
    std::string text_;
    int cursor_ = 0;

public:
    void type(const std::string& s) {
        text_.insert(cursor_, s);
        cursor_ += static_cast<int>(s.size());
    }

    void moveCursor(int pos) { cursor_ = pos; }

    // Create a snapshot
    std::unique_ptr<EditorMemento> save() const {
        return std::unique_ptr<EditorMemento>(
            new EditorMemento(text_, cursor_));
    }

    // Restore from a snapshot
    void restore(const EditorMemento& m) {
        text_ = m.text_;
        cursor_ = m.cursor_;
    }

    void print() const {
        std::cout << "Text: \"" << text_ << "\" (cursor=" << cursor_ << ")\n";
    }
};

// Caretaker - keeps the history, but never inspects mementos
class History {
    std::vector<std::unique_ptr<EditorMemento>> snapshots_;
public:
    void push(std::unique_ptr<EditorMemento> m) {
        snapshots_.push_back(std::move(m));
    }

    std::unique_ptr<EditorMemento> pop() {
        if (snapshots_.empty()) return nullptr;
        auto m = std::move(snapshots_.back());
        snapshots_.pop_back();
        return m;
    }

    bool empty() const { return snapshots_.empty(); }
};

int main() {
    Editor editor;
    History history;

    history.push(editor.save());          // snapshot: empty
    editor.type("Hello");
    editor.print();

    history.push(editor.save());          // snapshot: "Hello"
    editor.type(" World");
    editor.print();

    // Undo
    if (auto m = history.pop()) {
        editor.restore(*m);
        editor.print();                   // back to "Hello"
    }

    // Undo again
    if (auto m = history.pop()) {
        editor.restore(*m);
        editor.print();                   // back to empty
    }

    return 0;
}
```

**Pros**:
- Produce snapshots without violating encapsulation
- Simplifies originator by delegating history management to caretakers
- Maintains clean separation between state management and business logic

**Cons**:
- High RAM consumption if snapshots created frequently
- Caretakers must track originator lifecycle for cleanup
- Dynamic languages cannot guarantee memento state integrity

**Related**: Command + Memento (commands execute operations, mementos store pre-execution state for undo), Iterator (can capture iteration state), Prototype (simpler alternative for basic cloning)

**Note**: Memento is often used with Command pattern - Command handles the operation execution while Memento handles state restoration for undo.
