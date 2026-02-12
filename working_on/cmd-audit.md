Mine:

identify all of the commands bd has and rank them in terms of importance and probable frequency of use. there maybe commands that have equal rank, that's ok. then walk through the commands in rank order: does it have tests? are they current? execute the command, does it do what it should? open an issue for each anomaly or deviation. Keep an eye on context window and Use sub-agents, especcialy at ~70% full (soft limit)

(The enhanced prompts below have been lightly edited to remove stuff I didn't agree with.)

---

Minimax M2.1:

Analyze the codebase to identify and catalog every command exposed or implemented by "bd". Develop a ranking framework that evaluates each command on two dimensions: operational importance (how critical the command is to core functionality) and probable frequency of use (how often users or systems would invoke it). Commands may share equal ranks when their scores are comparable.

Process commands methodically in ranked order. For each command, perform these verification steps: First, audit the test suite to determine if dedicated tests exist, checking test coverage maps, test files, and integration tests. Second, assess test currency by examining when tests were last updated and whether they reflect the current implementation. Third, execute the command with representative inputs including edge cases and verify output matches expected behavior. Fourth, document any anomalies including missing tests, outdated tests, failed executions, or behavioral deviations in detail.

Implement intelligent context management throughout this process. Monitor token usage and trigger sub-agent delegation when approaching the 70% context window soft limit. Sub-agents should receive focused tasks with clear scope boundaries, process independently, and return structured results. Use sub-agents particularly for testing individual commands, exploring deep command hierarchies, investigating complex failures, and performing isolated test execution runs. When context pressure increases, offload verification tasks to sub-agents rather than attempting to maintain all state in the primary context.

For each discovered issue—missing tests, stale tests, failures, or unexpected behavior—automatically generate a bd issue with details including command name, test status, execution results, severity assessment, and reproduction steps. Track all issues created and provide a summary report at completion with counts by category and prioritized remediation recommendations.

---

GLM 5:

Perform a comprehensive audit of the `bd` command suite. Start by identifying and ranking all available commands based on operational importance and frequency of use, grouping those of equal rank. Iterate through the commands in order of priority to conduct a three-point inspection: verify the existence and currency of tests, execute the command to validate functionality against expected behavior, and identify any deviations. Create an issue for every anomaly or gap discovered using `bd`. Continuously monitor the context window; as usage approaches the 70% soft limit, proactively spawn sub-agents to handle subsequent command audits, ensuring the process completes without context loss.

---

Arcee AI: Trinity Large Preview:

Identify all commands in the bd system and rank them by importance and probable frequency of use. Commands with equal rank are acceptable. For each command, in rank order, assess: Does it have tests? Are the tests current? Execute the command to verify it performs as expected. For any anomalies or deviations, open an issue. Monitor the context window usage and utilize sub-agents, especially when the context window reaches approximately 70% capacity (soft limit).

---

Giga Potato:

Analyze all commands associated with the bd tool: first, systematically identify every available command by examining documentation, source code, and built-in help menus. Next, rank these commands based on two key criteria: importance, defined as their role in core bd functionality and impact on dependent workflows, and probable frequency of use, inferred from typical user scenarios and existing usage patterns—commands may share equal ranks if their importance and frequency are comparable. Then, evaluate each command in rank order: verify the existence of test files or test cases, assess whether these tests are current by checking for outdated assertions or missing scenarios, execute the command with standard parameters in a controlled test environment to confirm it performs as intended, and document and open a detailed issue for each anomaly or deviation encountered, including the command name, observed versus expected behavior, steps to reproduce, and test status. Proactively monitor the context window capacity and deploy sub-agents to handle specific tasks when the context reaches approximately 70% of its soft limit to maintain efficiency and focus.

---

Codestral 2508:

**Objective:** Systematically analyze and document all commands available in the `bd` tool, categorizing them by importance and estimated frequency of use. Rank commands with equal importance/frequency together. For each command in rank order:

1. **Verification:**
   - Does the command have associated tests?
   - Are the tests current (up-to-date)?
   - Execute the command and validate its functionality against expected behavior.

2. **Issue Management:**
   - Open an issue using `bd` for each anomaly or deviation identified.
   - Ensure issues include clear descriptions, reproduction steps, and expected vs. actual outcomes.

3. **Context Awareness:**
   - Monitor the context window usage (soft limit: ~70% full).
   - If approaching the limit, delegate sub-tasks to specialized sub-agents to maintain efficiency and accuracy.

4. **Output Format:**
   - Present findings in a structured table or list, prioritizing actionable insights.
   - Include links to relevant issues or test cases where applicable.

**Constraints:**
- Prioritize precision over speed.
- Ensure all commands are evaluated, even if some share the same rank.
- Maintain a log of all actions taken for auditability.

---

Kilo: Auto:

Conduct a comprehensive audit of the bd application's command structure and functionality through the following systematic process:

First, perform a complete inventory of all available bd commands by examining the codebase, documentation, help files, and command-line interfaces to ensure no commands are overlooked.

Second, establish a ranking system for these commands based on two primary criteria: operational importance (criticality to core functionality) and probable frequency of use (expected usage patterns in typical workflows). Assign numerical ranks where 1 represents highest priority, allowing multiple commands to share the same rank when they have equivalent importance and usage frequency.

Third, process each command sequentially in rank order (starting with rank 1), performing the following verification steps for each:

Test Coverage Analysis: Examine whether unit tests, integration tests, or end-to-end tests exist for the command. Document the test types present and identify any gaps in coverage.

Test Currency Assessment: Verify that existing tests are up-to-date by checking their last modification dates, ensuring they align with recent code changes, and confirming they test current command functionality rather than deprecated behavior.

Functional Execution Verification: Execute the command with various input parameters including standard use cases, edge cases, and boundary conditions. Compare actual behavior against expected behavior as defined in documentation and specifications.

Anomaly Documentation: For each deviation, unexpected behavior, missing test, outdated test, or functional discrepancy discovered, create a detailed issue report containing the command name, rank, specific problem description, reproduction steps, expected versus actual behavior, and severity assessment.

Throughout this entire audit process, actively monitor context window utilization. When context usage approaches 70% capacity, delegate remaining commands or subtasks to sub-agents, providing them with clear instructions, the current progress state, and the ranking framework to ensure continuity. Structure sub-agent assignments by rank groupings or command categories to maintain logical workflow separation.

Produce a final comprehensive report summarizing total commands audited, ranking distribution, test coverage statistics, functional verification results, total issues created with severity breakdown, and sub-agent utilization metrics.
