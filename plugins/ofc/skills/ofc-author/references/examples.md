# Worked examples

One valid deck containing each common card style. It uses the **folder** packaging, which is why
the image path is relative; in a bare `.ofc.json` that path would have to be an `https:` URL or a
`data:` URI.

| Card id                     | Style                                     | Rules shown |
|-----------------------------|-------------------------------------------|-------------|
| `http-idempotent`           | Q&A, explanation in `notes`, source link  | Q2, Q3, Q14 |
| `mitochondria`              | One-sided cloze                           | Q5          |
| `mariposa`, `mariposa-rev`  | Vocabulary, both directions, speech       | Q8, Q12     |
| `tcp-handshake-*`           | Ordered sequence as overlapping cloze     | Q4, Q5      |
| `big-o-binary-search`       | Code on the front, LaTeX answer           | Q10         |
| `robin`                     | Image prompt whose alt doesn't give it away | Q9, Q11   |
| `git-rebase-vs-merge`       | Choice with explanation and feedback      | Q6          |
| `oauth-flow`                | Diagram answer with alt                   | Q10, Q13    |

```json
{
  "$schema": "https://raw.githubusercontent.com/open-flashcard/schema/main/versions/v1.0.0/schema.json",
  "openflashcard": "1.0.0",
  "id": "urn:ofc:deck:example/style-guide",
  "name": "Card Style Examples",
  "description": "One card of each common style, for reference when authoring.",
  "lang": "en",
  "tags": ["examples"],
  "created": "2026-09-23T10:00:00Z",
  "cards": [
    {
      "id": "http-idempotent",
      "tags": ["web/http"],
      "front": [{ "type": "text", "text": "In HTTP, which property do PUT and DELETE have that POST does not guarantee?" }],
      "back": [{ "type": "text", "text": "Idempotence" }],
      "hint": [{ "type": "text", "text": "Sending the request twice has the same effect as sending it once." }],
      "notes": [
        { "type": "markdown", "text": "Repeating an **idempotent** request leaves the server in the same state. `GET`, `HEAD`, `PUT`, `DELETE` and `OPTIONS` are idempotent; `POST` and `PATCH` are not required to be." },
        { "type": "link", "href": "https://www.rfc-editor.org/rfc/rfc9110#section-9.2.2", "text": "RFC 9110 §9.2.2" }
      ]
    },
    {
      "id": "mitochondria",
      "tags": ["biology/cell"],
      "front": [{ "type": "cloze", "text": "ATP is mostly produced in the {{mitochondria|organelle}} of eukaryotic cells." }]
    },
    {
      "id": "mariposa",
      "tags": ["spanish/animals"],
      "front": [{ "type": "text", "text": "mariposa", "lang": "es", "style": "h1", "speech": { "rate": 0.8 } }],
      "back": [{ "type": "text", "text": "butterfly" }]
    },
    {
      "id": "mariposa-rev",
      "tags": ["spanish/animals"],
      "front": [{ "type": "text", "text": "butterfly", "style": "h1" }],
      "back": [{ "type": "text", "text": "la mariposa", "lang": "es", "speech": { "rate": 0.8 } }]
    },
    {
      "id": "tcp-handshake-1",
      "tags": ["networking/tcp"],
      "front": [{ "type": "cloze", "text": "TCP handshake: {{SYN}} → SYN-ACK → ACK" }]
    },
    {
      "id": "tcp-handshake-2",
      "tags": ["networking/tcp"],
      "front": [{ "type": "cloze", "text": "TCP handshake: SYN → {{SYN-ACK}} → ACK" }]
    },
    {
      "id": "tcp-handshake-3",
      "tags": ["networking/tcp"],
      "front": [{ "type": "cloze", "text": "TCP handshake: SYN → SYN-ACK → {{ACK}}" }]
    },
    {
      "id": "big-o-binary-search",
      "tags": ["cs/algorithms"],
      "front": [
        { "type": "text", "text": "Worst-case time complexity of this function?" },
        {
          "type": "code",
          "syntax": "python",
          "text": "def find(xs, t):\n    lo, hi = 0, len(xs) - 1\n    while lo <= hi:\n        mid = (lo + hi) // 2\n        if xs[mid] == t:\n            return mid\n        if xs[mid] < t:\n            lo = mid + 1\n        else:\n            hi = mid - 1\n    return -1"
        }
      ],
      "back": [{ "type": "latex", "text": "O(\\log n)", "display": "inline" }],
      "notes": [{ "type": "text", "text": "Each iteration halves the search interval, assuming xs is sorted." }]
    },
    {
      "id": "robin",
      "tags": ["birds/uk"],
      "front": [
        { "type": "text", "text": "Name this bird." },
        { "type": "image", "src": "img/robin.jpg", "alt": "A small, round brown bird with an orange-red face and breast, perched on a branch." }
      ],
      "back": [{ "type": "text", "text": "European robin (Erithacus rubecula)" }]
    },
    {
      "id": "git-rebase-vs-merge",
      "tags": ["git"],
      "front": [
        { "type": "text", "text": "You want to integrate main into your feature branch while keeping a linear history. Which command?" },
        {
          "type": "choice",
          "shuffle": true,
          "options": [
            { "content": [{ "type": "code", "text": "git rebase main" }], "correct": true },
            {
              "content": [{ "type": "code", "text": "git merge main" }],
              "feedback": [{ "type": "text", "text": "Merging creates a merge commit, so history is no longer linear." }]
            },
            { "content": [{ "type": "code", "text": "git cherry-pick main" }] },
            { "content": [{ "type": "code", "text": "git reset main" }] }
          ],
          "explanation": [{ "type": "markdown", "text": "`rebase` replays your commits on top of `main`, producing a linear history." }]
        }
      ]
    },
    {
      "id": "oauth-flow",
      "tags": ["security/oauth"],
      "front": [{ "type": "text", "text": "In the OAuth 2.0 authorization-code flow, what does the client exchange the authorization code for?" }],
      "back": [{ "type": "text", "text": "An access token (and optionally a refresh token)" }],
      "notes": [
        {
          "type": "mermaid",
          "alt": "Sequence: the user authorises at the authorization server, which redirects to the client with a code; the client posts the code to the token endpoint and receives an access token.",
          "text": "sequenceDiagram\n  User->>AuthServer: authorise\n  AuthServer-->>Client: redirect with code\n  Client->>AuthServer: POST /token (code)\n  AuthServer-->>Client: access token"
        }
      ]
    }
  ]
}
```
