---
name: write-incremental-spec
description: Write a spec of the code that was implemented, so the changes are easy to parse and developers can learn and keep track of how the framework works and the system evolves over time
---

When writing a spec, always follow these steps:

1. **Make sure code is compiling and relevant tests pass:** This guarantees we're writing a spec on top of a minimally-stable environment
2. **Write a paragraph that summarizes what the change was intended to accomplish:** Summary of the main asks from the developer
3. **Write a paragraph that summarizes the solution by citing the framework features that will be used, and what code change is involved (front-end, back-end, database etc.)**
4. **Create an ASCII diagram of the main components involved:** should include even those that may not have changed and show how the data flows through the user interaction
5. **Create a multi-level bullet list that describes the changes done to each file:** should include each function that was changed or added and a description of what it does now
6. **Save it to the /specs folder:** use the same file name convention as an Elixir/Ecto migration with date_description; description should be a 3-6 word max summary of the spec
