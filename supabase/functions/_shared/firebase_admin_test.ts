import { generatePartnerPasswordResetLink, issueFirebasePartnerPassword } from "./firebase_admin.ts";

const uid = "kaylo-partner-test";
const partnerId = "KP-000001";
const email = "kp-000001@partners.kaylo.app";
const password = "temporary-test-password";
const issuanceId = "00000000-0000-4000-8000-000000000001";
const claims = {
  kaylo_role: "worker",
  kaylo_partner_id: partnerId,
  kaylo_issuance_id: issuanceId,
};
const key = await crypto.subtle.generateKey(
  {
    name: "RSASSA-PKCS1-v1_5",
    modulusLength: 2048,
    publicExponent: new Uint8Array([1, 0, 1]),
    hash: "SHA-256",
  },
  true,
  ["sign", "verify"],
);
const der = new Uint8Array(
  await crypto.subtle.exportKey("pkcs8", key.privateKey),
);
const encoded = btoa(String.fromCharCode(...der));
const privateKey = `-----BEGIN PRIVATE KEY-----\n${
  encoded.match(/.{1,64}/g)!.join("\n")
}\n-----END PRIVATE KEY-----`;
Deno.env.set(
  "FIREBASE_SERVICE_ACCOUNT_B64",
  btoa(JSON.stringify({
    project_id: "kaylo-test",
    client_email: "test@kaylo-test.iam.gserviceaccount.com",
    private_key: privateKey,
  })),
);

function assert(
  condition: unknown,
  message = "assertion failed",
): asserts condition {
  if (!condition) throw new Error(message);
}
type Account = {
  localId: string;
  email: string;
  customAttributes?: string;
  passwordUpdatedAt?: number;
  disabled?: boolean;
};
type RequestRecord = { endpoint: string; body: Record<string, unknown> };
async function withFirebase(
  options: {
    existing?: boolean;
    final?: Partial<Account>;
    failureEndpoint?: string;
    emailOwner?: string;
  },
  check: (
    requests: RequestRecord[],
    issue: () => Promise<number>,
  ) => Promise<void>,
) {
  const originalFetch = globalThis.fetch;
  const requests: RequestRecord[] = [];
  let mutated = false;
  const initial: Account = {
    localId: uid,
    email,
    passwordUpdatedAt: 1000,
    customAttributes: JSON.stringify(claims),
  };
  const final: Account = {
    ...initial,
    passwordUpdatedAt: 2000,
    disabled: false,
    ...options.final,
  };
  globalThis.fetch = (input, init) => {
    const url = String(input);
    if (url === "https://oauth2.googleapis.com/token") {
      return Promise.resolve(
        Response.json({ access_token: "test-access-token" }),
      );
    }
    assert(
      url.startsWith(
        "https://identitytoolkit.googleapis.com/v1/projects/kaylo-test/",
      ),
      "Unexpected network request",
    );
    const endpoint = url.split("/").at(-1)!;
    const body = JSON.parse(String(init?.body));
    requests.push({ endpoint, body });
    if (options.failureEndpoint === endpoint) {
      return Promise.resolve(
        Response.json({ error: { message: "SECRET_AUTH_MATERIAL" } }, {
          status: 500,
        }),
      );
    }
    if (endpoint === "accounts:lookup") {
      if (body.email) {
        return Promise.resolve(Response.json({
          users: options.emailOwner
            ? [{ localId: options.emailOwner }]
            : options.existing
            ? [initial]
            : [],
        }));
      }
      return Promise.resolve(
        Response.json({
          users: mutated ? [final] : options.existing ? [initial] : [],
        }),
      );
    }
    if (endpoint === "accounts" || endpoint === "accounts:update") {
      mutated = true;
      return Promise.resolve(Response.json({ localId: uid }));
    }
    throw new Error(`Unexpected Firebase endpoint ${endpoint}`);
  };
  try {
    await check(
      requests,
      () =>
        issueFirebasePartnerPassword(
          uid,
          partnerId,
          password,
          "Test Partner",
          issuanceId,
        ),
    );
  } finally {
    globalThis.fetch = originalFetch;
  }
}

Deno.test("new partner sets claims with accounts:update after creating the password identity", async () => {
  await withFirebase({}, async (requests, issue) => {
    assert(await issue() === 2000);
    const writes = requests.filter((r) => r.endpoint !== "accounts:lookup");
    assert(
      writes.length === 2 && writes[0].endpoint === "accounts" &&
        writes[1].endpoint === "accounts:update",
      "Create must be followed by explicit claims update",
    );
    assert(
      writes[0].body.password === password && writes[0].body.email === email,
    );
    assert(
      !("customAttributes" in writes[0].body),
      "Create endpoint does not support custom claims",
    );
    assert(writes[1].body.localId === uid);
    assert(
      JSON.stringify(JSON.parse(String(writes[1].body.customAttributes))) ===
        JSON.stringify(claims),
    );
    assert(
      requests.at(-1)?.endpoint === "accounts:lookup",
      "Issuance must read back the persisted claims",
    );
  });
});
Deno.test("existing partner reset updates password, issuance claims and session revocation", async () => {
  await withFirebase({ existing: true }, async (requests, issue) => {
    assert(await issue() === 2000);
    const writes = requests.filter((r) => r.endpoint !== "accounts:lookup");
    assert(writes.length === 1 && writes[0].endpoint === "accounts:update");
    assert(
      writes[0].body.password === password && writes[0].body.localId === uid,
    );
    assert(Number(writes[0].body.validSince) > 0);
    assert(
      JSON.stringify(JSON.parse(String(writes[0].body.customAttributes))) ===
        JSON.stringify(claims),
    );
  });
});
Deno.test("issuance rejects missing, malformed or incorrect persisted partner claims", async () => {
  for (
    const customAttributes of [
      undefined,
      "{}",
      "not-json",
      "null",
      JSON.stringify({ ...claims, kaylo_issuance_id: "wrong" }),
      JSON.stringify({ ...claims, kaylo_role: "customer" }),
      JSON.stringify({ ...claims, kaylo_partner_id: "KP-999999" }),
    ]
  ) {
    await withFirebase(
      { final: { customAttributes } },
      async (_requests, issue) => {
        let rejected = false;
        try {
          await issue();
        } catch {
          rejected = true;
        }
        assert(
          rejected,
          "Do not deliver credentials whose claims were not persisted",
        );
      },
    );
  }
});
Deno.test("issuance rejects changed UID, email or disabled Firebase account", async () => {
  for (
    const final of [{ localId: "someone-else" }, {
      email: "other@example.invalid",
    }, { disabled: true }]
  ) {
    await withFirebase({ final }, async (_requests, issue) => {
      let rejected = false;
      try {
        await issue();
      } catch {
        rejected = true;
      }
      assert(
        rejected,
        "Read-back identity must match the requested enabled partner",
      );
    });
  }
});
Deno.test("issuance rejects unavailable password timestamps", async () => {
  for (const passwordUpdatedAt of [undefined, 0, -1]) {
    await withFirebase(
      { final: { passwordUpdatedAt } },
      async (_requests, issue) => {
        let rejected = false;
        try {
          await issue();
        } catch {
          rejected = true;
        }
        assert(rejected);
      },
    );
  }
});
Deno.test("claims update failure does not leak Firebase response or report issuance success", async () => {
  await withFirebase(
    { failureEndpoint: "accounts:update" },
    async (_requests, issue) => {
      let message = "";
      try {
        await issue();
      } catch (error) {
        message = (error as Error).message;
      }
      assert(
        message && !message.includes("SECRET_AUTH_MATERIAL") &&
          !message.includes(password),
      );
    },
  );
});
Deno.test("partner email ownership conflict performs no account mutation", async () => {
  await withFirebase({ emailOwner: "other-owner" }, async (requests, issue) => {
    let message = "";
    try {
      await issue();
    } catch (error) {
      message = (error as Error).message;
    }
    assert(message === "PARTNER_EMAIL_ALREADY_CLAIMED");
    assert(requests.every((r) => r.endpoint === "accounts:lookup"));
  });
});


Deno.test("recovery links target only the matching issued Firebase alias", async () => {
  const original = globalThis.fetch;
  let current: Account | null = {localId:uid,email,customAttributes:JSON.stringify(claims)};
  let resetRequests = 0;
  globalThis.fetch = async (input, init) => {
    const url = String(input);
    if (url === "https://oauth2.googleapis.com/token") return Response.json({access_token:"test",expires_in:3600});
    const body = JSON.parse(String(init?.body));
    if (url.endsWith("accounts:lookup")) return Response.json({users:current?[current]:[]});
    assert(url === "https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode");
    assert(body.email===email && body.returnOobLink===true && body.requestType==="PASSWORD_RESET");
    assert(body.targetProjectId==="kaylo-test");
    resetRequests++;
    return Response.json({oobLink:"https://kaylo-test.firebaseapp.com/__/auth/action?mode=resetPassword&oobCode=test-code"});
  };
  try {
    const identity = {firebase_uid:uid, partner_id:partnerId, issuance_id:issuanceId};
    assert((await generatePartnerPasswordResetLink(identity))?.includes("oobCode=test-code"));
    assert(resetRequests===1);
    for (const invalid of [null, {localId:uid,email,disabled:true},
      {localId:uid,email:"customer@example.com"},
      {localId:uid,email,customAttributes:JSON.stringify({...claims,kaylo_issuance_id:"stale"})}]) {
      current=invalid;
      assert(await generatePartnerPasswordResetLink(identity)===null);
    }
    assert(resetRequests===1);
  } finally { globalThis.fetch=original; }
});
