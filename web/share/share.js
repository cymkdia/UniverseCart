(function () {
  "use strict";

const mallNames = {
  cm29: "29CM",
  musinsa: "무신사",
  wconcept: "W컨셉",
  naver: "네이버",
  kurly: "마켓컬리",
  etc: "기타",
};

const categoryNames = {
  fashion: "패션",
  beauty: "뷰티",
  home: "홈리빙",
  appliance: "가전",
  food: "식품",
  sports: "스포츠",
};

let supabase = null;
let ownerProfile = null;
let wishItems = [];
let pledgesByItem = {};
let coordinationsByItem = {};
let activeItem = null;
let selectedAmount = null;
let authMode = "signin";

function escapeHtml(value) {
  return String(value ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function formatPrice(value) {
  if (value == null) return "가격 미입력";
  return "₩" + Number(value).toLocaleString("ko-KR");
}

function getSlug() {
  return new URLSearchParams(window.location.search).get("slug");
}

function getPledgeItemId() {
  return new URLSearchParams(window.location.search).get("item");
}

function openPledgeFromQuery() {
  const itemId = getPledgeItemId();
  if (!itemId) return;

  const item = wishItems.find(
    (entry) => String(entry.id).toLowerCase() === itemId.toLowerCase()
  );
  if (item) {
    openPledgeSheet(item);
  }
}

function pledgesForItem(itemId) {
  return pledgesByItem[itemId] || [];
}

function coordinationForItem(itemId) {
  return coordinationsByItem[itemId] || null;
}

function effectiveCoordState(item, stats) {
  const coord = coordinationForItem(item.id);
  if (coord?.state === "received") return "received";
  if (coord?.state === "purchased") return "purchased";
  if (coord?.state === "buyer_assigned") return "buyer_assigned";
  if (coord?.state === "goal_reached") return "goal_reached";
  if (item.price && stats.total >= item.price) return "goal_reached";
  return stats.pledges.length ? "collecting" : "collecting";
}

function isGoalMet(item, stats) {
  return item.price && item.price > 0 && stats.total >= item.price;
}

function fundingStats(item) {
  const pledges = pledgesForItem(item.id);
  const total = pledges.reduce((sum, p) => sum + p.amount, 0);
  const price = item.price;
  const pct =
    price && price > 0
      ? Math.min(100, Math.round((total / price) * 100))
      : null;
  const remaining =
    price && price > 0 ? Math.max(0, price - total) : null;
  return { pledges, total, pct, remaining };
}

function contributorLabel(pledge) {
  return pledge.contributor_name || "친구";
}

function renderItems(ownerName, items) {
  const title = document.getElementById("ownerTitle");
  const summary = document.getElementById("summary");
  const content = document.getElementById("content");

  title.textContent = ownerName
    ? `${ownerName}님의 위시리스트`
    : "위시리스트";

  const priced = items.filter((i) => i.price != null);
  const total = priced.reduce((sum, i) => sum + i.price, 0);

  summary.innerHTML =
    `담은 것 <strong>${items.length}개</strong>` +
    (priced.length
      ? ` · 합계 <strong>₩${total.toLocaleString("ko-KR")}</strong>`
      : "");

  if (!items.length) {
    content.className = "state";
    content.textContent = "아직 공개된 위시 상품이 없어요.";
    return;
  }

  content.className = "list";
  content.innerHTML = items
    .map((item) => {
      const mall = mallNames[item.mall] || item.mall;
      const cat = categoryNames[item.category] || item.category;
      const thumb = item.image_url
        ? `<img src="${item.image_url}" alt="" />`
        : "";
      const stats = fundingStats(item);
      const coordState = effectiveCoordState(item, stats);
      const goalMet = isGoalMet(item, stats);
      const names = stats.pledges
        .slice(0, 3)
        .map((p) => contributorLabel(p))
        .join(", ");
      const participantLine = stats.pledges.length
        ? `${stats.pledges.length}명 참여` +
          (names ? ` · ${names}` : "")
        : "아직 약속이 없어요";

      let fundHTML = "";
      if (stats.pledges.length || item.price) {
        const barWidth = stats.pct != null ? stats.pct : 0;
        fundHTML = `
          <div class="fund-block">
            ${
              stats.pct != null
                ? `<div class="fund-top">
                    <span class="fund-label">약속 펀딩</span>
                    <span class="fund-pct">${goalMet ? "100%" : stats.pct + "%"}</span>
                    ${goalMet ? '<span class="fund-label" style="color:#3a8c5c;margin-left:6px">목표 달성</span>' : ""}
                  </div>
                  <div class="fund-bar"><div class="fund-fill" style="width:${goalMet ? 100 : barWidth}%"></div></div>
                  <div class="fund-meta">
                    <span class="fund-collected">${formatPrice(stats.total)} 모였어요</span>
                    <span class="fund-remaining">${goalMet ? "목표 달성" : formatPrice(stats.remaining) + " 남았어요"}</span>
                  </div>`
                : `<div class="fund-meta">
                    <span class="fund-collected">${formatPrice(stats.total)} 약속</span>
                  </div>`
            }
            <div class="fund-participants">${participantLine}</div>
            <div class="btn-row">
              <button type="button" class="btn btn-primary" data-pledge="${item.id}">
                ${goalMet ? "참여 현황 보기" : "같이 선물하기"}
              </button>
              ${
                item.product_url
                  ? `<a class="btn btn-secondary" href="${escapeHtml(item.product_url)}" target="_blank" rel="noopener">쇼핑몰에서 보기</a>`
                  : ""
              }
            </div>
          </div>
        `;
      } else {
        fundHTML = `
          <div class="btn-row" style="margin-top:12px">
            <button type="button" class="btn btn-primary" data-pledge="${item.id}">
              같이 선물하기
            </button>
          </div>
        `;
      }

      return `
        <article class="item">
          <div class="item-top">
            <div class="thumb">${thumb}</div>
            <div class="body">
              <div class="meta">${mall} · ${cat}</div>
              <div class="title">${escapeHtml(item.title)}</div>
              <div class="price">${formatPrice(item.price)}</div>
            </div>
          </div>
          ${fundHTML}
        </article>
      `;
    })
    .join("");

  content.querySelectorAll("[data-pledge]").forEach((button) => {
    button.addEventListener("click", () => {
      const itemId = button.getAttribute("data-pledge");
      const item = wishItems.find((i) => i.id === itemId);
      if (item) openPledgeSheet(item);
    });
  });
}

function defaultAmounts(item) {
  const price = item.price || 0;
  const stats = fundingStats(item);
  const remaining = stats.remaining ?? price;
  const options = [];

  if (remaining > 0) {
    const small = Math.min(50000, remaining);
    if (small >= 1000) {
      options.push({ value: small, label: "소액 참여" });
    }
    const third = Math.round(remaining / 3 / 1000) * 1000;
    if (third >= 1000 && third !== small) {
      options.push({ value: third, label: "1/3 분담" });
    }
    options.push({ value: remaining, label: "나머지 전부" });
  }

  options.push({ value: "custom", label: "직접 입력" });
  return options.slice(0, 4);
}

async function getSessionUser() {
  const { data } = await supabase.auth.getSession();
  return data.session?.user ?? null;
}

function closeSheet() {
  document.getElementById("overlay").classList.remove("open");
  activeItem = null;
}

function readAuthFieldValues() {
  return {
    email: document.getElementById("authEmail")?.value?.trim() || "",
    password: document.getElementById("authPassword")?.value || "",
  };
}

function renderAuthForm(container, errorText, options = {}) {
  const {
    successText = "",
    preserveEmail = "",
    preservePassword = "",
  } = options;
  const submitLabel =
    authMode === "signin" ? "로그인하고 약속하기" : "가입하고 약속하기";

  container.innerHTML = `
    <div class="auth-tabs">
      <button type="button" class="auth-tab ${authMode === "signin" ? "on" : ""}" data-auth-mode="signin">로그인</button>
      <button type="button" class="auth-tab ${authMode === "signup" ? "on" : ""}" data-auth-mode="signup">회원가입</button>
    </div>
    ${successText ? `<div class="form-success">${escapeHtml(successText)}</div>` : ""}
    ${errorText ? `<div class="form-error">${escapeHtml(errorText)}</div>` : ""}
    <form id="authForm" novalidate>
      <div class="field">
        <label for="authEmail">이메일</label>
        <input
          id="authEmail"
          name="email"
          type="email"
          inputmode="email"
          autocomplete="email"
          placeholder="you@example.com"
          value="${escapeHtml(preserveEmail)}"
          required
        />
      </div>
      <div class="field">
        <label for="authPassword">비밀번호</label>
        <input
          id="authPassword"
          name="password"
          type="password"
          autocomplete="${authMode === "signup" ? "new-password" : "current-password"}"
          placeholder="6자 이상"
          value="${escapeHtml(preservePassword)}"
          minlength="6"
          required
        />
      </div>
      <button type="submit" class="btn btn-primary" id="authSubmit" style="width:100%">
        ${submitLabel}
      </button>
    </form>
  `;

  container.querySelectorAll("[data-auth-mode]").forEach((tab) => {
    tab.addEventListener("click", () => {
      const { email, password } = readAuthFieldValues();
      authMode = tab.getAttribute("data-auth-mode");
      renderAuthForm(container, "", { preserveEmail: email, preservePassword: password });
    });
  });

  document.getElementById("authForm").addEventListener("submit", async (event) => {
    event.preventDefault();

    const email = document.getElementById("authEmail").value.trim();
    const password = document.getElementById("authPassword").value;
    const submitButton = document.getElementById("authSubmit");

    if (!email || !password) {
      renderAuthForm(container, "이메일과 비밀번호를 입력해 주세요.", {
        preserveEmail: email,
        preservePassword: password,
      });
      return;
    }

    if (password.length < 6) {
      renderAuthForm(container, "비밀번호는 6자 이상이어야 해요.", {
        preserveEmail: email,
        preservePassword: password,
      });
      return;
    }

    submitButton.disabled = true;
    submitButton.textContent = "처리 중…";

    try {
      const result =
        authMode === "signin"
          ? await supabase.auth.signInWithPassword({ email, password })
          : await supabase.auth.signUp({ email, password });

      if (result.error) throw result.error;

      if (authMode === "signup") {
        const alreadyRegistered =
          result.data.user?.identities?.length === 0;
        if (alreadyRegistered) {
          authMode = "signin";
          renderAuthForm(
            container,
            "이미 가입된 이메일이에요. 로그인 탭에서 로그인해 주세요.",
            { preserveEmail: email }
          );
          return;
        }

        if (!result.data.session) {
          authMode = "signin";
          renderAuthForm(container, "", {
            successText:
              "가입했어요! 이메일 확인이 필요하면 메일함을 확인한 뒤 로그인해 주세요.",
            preserveEmail: email,
          });
          return;
        }
      }

      const user = result.data.session?.user ?? (await getSessionUser());
      if (!user) {
        renderAuthForm(container, "로그인에 실패했어요. 다시 시도해 주세요.", {
          preserveEmail: email,
        });
        return;
      }

      renderPledgeForm(container, user, "", "");
    } catch (error) {
      renderAuthForm(container, error.message || String(error), {
        preserveEmail: email,
        preservePassword: password,
      });
    }
  });
}

function renderPledgeForm(container, user, errorText, successText) {
  const item = activeItem;
  const stats = fundingStats(item);
  const options = defaultAmounts(item);
  if (selectedAmount == null) {
    const preferred = options.find((o) => o.value !== "custom");
    selectedAmount = preferred ? preferred.value : "";
  }

  const existing = stats.pledges.find(
    (p) => p.contributor_user_id === user.id
  );

  container.innerHTML = `
    <div class="session-bar">로그인: ${user.email}</div>
    ${successText ? `<div class="form-success">${successText}</div>` : ""}
    ${errorText ? `<div class="form-error">${errorText}</div>` : ""}
    ${
      existing
        ? `<p class="sheet-sub" style="margin-top:0">이미 남긴 약속이 있어요. 금액을 바꾸면 업데이트됩니다.</p>`
        : ""
    }
    <div class="amount-grid" id="amountGrid">
      ${options
        .map((opt) => {
          const isOn =
            opt.value === "custom"
              ? selectedAmount === "custom"
              : selectedAmount === opt.value;
          const valText =
            opt.value === "custom"
              ? "직접 입력"
              : formatPrice(opt.value);
          return `<button type="button" class="amt-chip ${isOn ? "on" : ""}" data-amount="${opt.value}">
            <div class="amt-val">${valText}</div>
            <div class="amt-label">${opt.label}</div>
          </button>`;
        })
        .join("")}
    </div>
    <div class="field" id="customAmountField" style="display:${selectedAmount === "custom" ? "block" : "none"}">
      <label for="customAmount">금액 (원)</label>
      <input id="customAmount" type="number" min="1000" step="1000" placeholder="50000" />
    </div>
    <div class="field">
      <label for="pledgeMessage">한마디 (선택)</label>
      <textarea id="pledgeMessage" placeholder="생일 축하해! 같이 선물해요">${existing?.message || ""}</textarea>
    </div>
    <button type="button" class="btn btn-primary" id="submitPledge" style="width:100%;margin-bottom:8px">
      약속 남기기
    </button>
    <p class="sheet-sub" style="margin:0;text-align:center">
      UC는 결제를 받지 않아요. 실제 송금은 카톡·계좌 등에서 진행해 주세요.
    </p>
  `;

  container.querySelectorAll("[data-amount]").forEach((chip) => {
    chip.addEventListener("click", () => {
      const raw = chip.getAttribute("data-amount");
      selectedAmount = raw === "custom" ? "custom" : Number(raw);
      renderPledgeForm(container, user, "", "");
    });
  });

  document.getElementById("submitPledge").addEventListener("click", async () => {
    let amount = selectedAmount;
    if (amount === "custom") {
      amount = Number(document.getElementById("customAmount").value);
    }
    const message = document.getElementById("pledgeMessage").value.trim();

    if (!amount || amount < 1000) {
      renderPledgeForm(container, user, "1,000원 이상 금액을 입력해 주세요.", "");
      return;
    }

    if (user.id === ownerProfile.user_id) {
      renderPledgeForm(container, user, "본인 위시에는 약속할 수 없어요.", "");
      return;
    }

    const displayName =
      user.email?.split("@")[0] || "친구";

    try {
      const { error } = await supabase.from("funding_pledges").upsert(
        {
          item_id: item.id,
          contributor_user_id: user.id,
          amount: Math.round(amount),
          message: message || null,
          contributor_name: displayName,
          updated_at: new Date().toISOString(),
        },
        { onConflict: "item_id,contributor_user_id" }
      );
      if (error) throw error;

      await reloadPledges();
      await reloadCoordinations();
      renderItems(ownerProfile.display_name, wishItems);
      renderPledgeForm(
        container,
        user,
        "",
        `${formatPrice(Math.round(amount))} 약속을 남겼어요!`
      );
      renderCoordinationSection(container, user);
    } catch (error) {
      renderPledgeForm(container, user, error.message || String(error), "");
    }
  });
}

const WEB_BANK_OPTIONS = [
  { name: "KB국민", code: "004", toss: "KB국민" },
  { name: "신한", code: "088", toss: "신한" },
  { name: "우리", code: "020", toss: "우리" },
  { name: "NH농협", code: "011", toss: "NH농협" },
  { name: "카카오뱅크", code: "090", toss: "카카오" },
  { name: "토스뱅크", code: "092", toss: "토스" },
];

function kakaoPayLink(bankCode, accountNumber, amount) {
  const acct = String(accountNumber).replace(/\D/g, "");
  return `kakaopay://money/to/bank?bank_code=${encodeURIComponent(bankCode)}&bank_account_number=${encodeURIComponent(acct)}&amount=${encodeURIComponent(String(amount))}`;
}

function tossPayLink(bankName, accountNumber, amount) {
  const acct = String(accountNumber).replace(/\D/g, "");
  return `supertoss://send?bank=${encodeURIComponent(bankName)}&accountNo=${encodeURIComponent(acct)}&amount=${encodeURIComponent(String(amount))}`;
}

async function insertCoordinationNotifications(itemId, kind, title, ownerBody, participantBody) {
  const stats = fundingStats(activeItem);
  const payloads = [
    {
      user_id: ownerProfile.user_id,
      item_id: itemId,
      kind,
      title,
      body: ownerBody,
    },
  ];
  stats.pledges.forEach((p) => {
    if (p.contributor_user_id !== ownerProfile.user_id) {
      payloads.push({
        user_id: p.contributor_user_id,
        item_id: itemId,
        kind,
        title,
        body: participantBody,
      });
    }
  });
  const { error } = await supabase.from("funding_notifications").insert(payloads);
  if (error) console.warn("notification insert failed:", error);
}

function renderCoordinationSection(container, user) {
  const item = activeItem;
  if (!item) return;

  const existing = document.getElementById("coordSection");
  if (existing) existing.remove();

  const stats = fundingStats(item);
  const state = effectiveCoordState(item, stats);
  const coord = coordinationForItem(item.id);
  const isParticipant = stats.pledges.some((p) => p.contributor_user_id === user.id);
  const isOwner = user.id === ownerProfile.user_id;
  const isBuyer = coord?.buyer_user_id === user.id;

  if (state === "collecting" && !isGoalMet(item, stats)) return;

  const section = document.createElement("div");
  section.id = "coordSection";
  section.style.marginTop = "16px";
  section.style.paddingTop = "16px";
  section.style.borderTop = "1px solid #e4e4e4";

  let html = `<div class="form-success" style="margin-bottom:10px">약속 목표를 달성했어요!</div>`;
  html += `<p class="sheet-sub" style="margin-top:0">UC는 결제·송금을 처리하지 않아요. 카카오페이·토스에서 직접 송금해 주세요.</p>`;

  if (state === "goal_reached" && isParticipant && !isOwner) {
    html += `
      <p class="sheet-sub">대표 구매자로 손들기</p>
      <div class="field">
        <label for="volBank">은행</label>
        <select id="volBank">${WEB_BANK_OPTIONS.map((b) => `<option value="${b.code}" data-toss="${b.toss}">${b.name}</option>`).join("")}</select>
      </div>
      <div class="field">
        <label for="volAccount">송금받을 계좌번호</label>
        <input id="volAccount" inputmode="numeric" placeholder="하이픈 없이" />
      </div>
      <button type="button" class="btn btn-primary" id="volunteerBtn" style="width:100%;margin-bottom:8px">내가 대표로 살게요</button>
    `;
  }

  if ((state === "buyer_assigned" || state === "purchased") && coord?.settlement_account_number) {
    html += `<p class="sheet-sub"><strong>대표 계좌</strong> ${escapeHtml(coord.settlement_bank_name || "")} ${escapeHtml(coord.settlement_account_number)}</p>`;
    stats.pledges
      .filter((p) => p.contributor_user_id !== ownerProfile.user_id)
      .forEach((p) => {
        const isMe = p.contributor_user_id === user.id;
        html += `
          <div style="margin-bottom:10px;padding:10px;background:#f7f6f3;border-radius:8px">
            <div style="font-size:13px;font-weight:600;margin-bottom:6px">${escapeHtml(p.contributor_name || "친구")}${isMe ? " (나)" : ""} · ${formatPrice(p.amount)}</div>
            <div class="btn-row">
              <a class="btn btn-secondary" href="${kakaoPayLink(coord.settlement_bank_code, coord.settlement_account_number, p.amount)}">카카오페이</a>
              <a class="btn btn-secondary" href="${tossPayLink(coord.settlement_bank_name, coord.settlement_account_number, p.amount)}">토스</a>
            </div>
          </div>
        `;
      });

    const shareLines = [
      "[Universe Cart] 정산 안내",
      `${item.title}`,
      `계좌: ${coord.settlement_bank_name} ${coord.settlement_account_number}`,
    ];
    stats.pledges.forEach((p) => {
      if (p.contributor_user_id !== ownerProfile.user_id) {
        shareLines.push(`- ${p.contributor_name}: ${formatPrice(p.amount)}`);
      }
    });
    html += `<button type="button" class="btn btn-primary" id="shareSettlement" style="width:100%;margin-bottom:8px">카카오톡으로 정산 안내 공유</button>`;
    section.dataset.shareText = shareLines.join("\n");
  }

  if (state === "buyer_assigned" && isBuyer) {
    html += `<button type="button" class="btn btn-primary" id="markPurchased" style="width:100%;margin-bottom:8px">구매 완료</button>`;
  }

  if (state === "purchased" && isOwner) {
    html += `<p class="sheet-sub">선물을 받으셨나요? 앱에서 「선물 받음」을 눌러 주세요.</p>`;
  }

  section.innerHTML = html;
  container.appendChild(section);

  const volunteerBtn = section.querySelector("#volunteerBtn");
  if (volunteerBtn) {
    volunteerBtn.addEventListener("click", async () => {
      const bankSelect = section.querySelector("#volBank");
      const account = section.querySelector("#volAccount").value.replace(/\D/g, "");
      const bankCode = bankSelect.value;
      const bankName = bankSelect.selectedOptions[0]?.dataset?.toss || bankSelect.selectedOptions[0]?.textContent;
      if (account.length < 10) {
        alert("계좌번호를 10자리 이상 입력해 주세요.");
        return;
      }
      try {
        const { error } = await supabase.from("funding_coordinations").upsert(
          {
            item_id: item.id,
            owner_user_id: ownerProfile.user_id,
            buyer_user_id: user.id,
            state: "buyer_assigned",
            settlement_bank_name: bankName,
            settlement_bank_code: bankCode,
            settlement_account_number: account,
            updated_at: new Date().toISOString(),
          },
          { onConflict: "item_id" }
        );
        if (error) throw error;
        await insertCoordinationNotifications(
          item.id,
          "buyer_assigned",
          "대표 구매자가 정해졌어요",
          "참여자들이 송금할 수 있도록 정산 안내를 확인해 주세요.",
          "대표 구매자에게 약속 금액을 송금해 주세요."
        );
        await reloadCoordinations();
        renderCoordinationSection(container, user);
      } catch (err) {
        alert(err.message || String(err));
      }
    });
  }

  const purchasedBtn = section.querySelector("#markPurchased");
  if (purchasedBtn) {
    purchasedBtn.addEventListener("click", async () => {
      try {
        const { error } = await supabase
          .from("funding_coordinations")
          .update({
            state: "purchased",
            purchased_at: new Date().toISOString(),
            updated_at: new Date().toISOString(),
          })
          .eq("item_id", item.id)
          .eq("buyer_user_id", user.id);
        if (error) throw error;
        await insertCoordinationNotifications(
          item.id,
          "purchased",
          "구매가 완료됐어요",
          "선물이 도착하면 「선물 받음」을 눌러 주세요.",
          "대표 구매자가 구매를 완료했어요."
        );
        await reloadCoordinations();
        renderCoordinationSection(container, user);
      } catch (err) {
        alert(err.message || String(err));
      }
    });
  }

  const shareBtn = section.querySelector("#shareSettlement");
  if (shareBtn && section.dataset.shareText) {
    shareBtn.addEventListener("click", async () => {
      const text = section.dataset.shareText;
      if (navigator.share) {
        try {
          await navigator.share({ text });
          return;
        } catch (_) {}
      }
      await navigator.clipboard.writeText(text);
      alert("정산 안내를 복사했어요. 카카오톡에 붙여넣기해 주세요.");
    });
  }
}

async function openPledgeSheet(item) {
  activeItem = item;
  selectedAmount = null;
  const overlay = document.getElementById("overlay");
  const sheetSub = document.getElementById("sheetSub");
  const sheetBody = document.getElementById("sheetBody");

  document.getElementById("sheetTitle").textContent = "같이 선물하기";
        sheetSub.textContent = item.title || "";
  overlay.classList.add("open");

  const user = await getSessionUser();
  if (!user) {
    renderAuthForm(sheetBody, "");
    return;
  }

  renderPledgeForm(sheetBody, user, "", "");
  renderCoordinationSection(sheetBody, user);
}

async function reloadPledges() {
  pledgesByItem = {};
  if (!wishItems.length) return true;

  const ids = wishItems.map((i) => i.id);
  const { data, error } = await supabase
    .from("funding_pledges")
    .select(
      "id, item_id, contributor_user_id, amount, message, contributor_name, created_at"
    )
    .in("item_id", ids)
    .order("created_at", { ascending: false });

  if (error) {
    console.warn("funding_pledges load failed:", error);
    return false;
  }

  (data || []).forEach((pledge) => {
    if (!pledgesByItem[pledge.item_id]) {
      pledgesByItem[pledge.item_id] = [];
    }
    pledgesByItem[pledge.item_id].push(pledge);
  });
  return true;
}

async function reloadCoordinations() {
  coordinationsByItem = {};
  if (!wishItems.length) return true;

  const ids = wishItems.map((i) => i.id);
  const { data, error } = await supabase
    .from("funding_coordinations")
    .select(
      "item_id, owner_user_id, state, buyer_user_id, goal_reached_at, purchased_at, received_at, thank_you_message, settlement_bank_name, settlement_bank_code, settlement_account_number, updated_at"
    )
    .in("item_id", ids);

  if (error) {
    console.warn("funding_coordinations load failed:", error);
    return false;
  }

  (data || []).forEach((coord) => {
    coordinationsByItem[coord.item_id] = coord;
  });
  return true;
}

function showFatal(message) {
  document.getElementById("summary").textContent = "불러오지 못했어요";
  const content = document.getElementById("content");
  content.className = "state error";
  content.textContent = message;
}

function bindSheetEvents() {
  document.getElementById("closeSheet").addEventListener("click", closeSheet);
  document.getElementById("overlay").addEventListener("click", (event) => {
    if (event.target.id === "overlay") closeSheet();
  });
}

async function main() {
  const content = document.getElementById("content");
  const slug = getSlug();
  const config = window.UNIVERSE_CART_CONFIG;

  if (!slug) {
    content.className = "state error";
    content.textContent =
      "공유 링크가 올바르지 않아요. (?slug=주소) 가 포함된 링크인지 확인해 주세요.";
    document.getElementById("summary").textContent = "";
    return;
  }

  if (!config?.SUPABASE_URL || !config?.SUPABASE_ANON_KEY) {
    content.className = "state error";
    content.textContent =
      "config.js 가 없어요. config.example.js 를 복사해 config.js 를 만들고 Supabase URL·키를 넣어 주세요.";
    document.getElementById("summary").textContent = "";
    return;
  }

  if (!window.supabase?.createClient) {
    throw new Error("Supabase 스크립트를 불러오지 못했어요. 네트워크 연결 후 새로고침해 주세요.");
  }

  supabase = window.supabase.createClient(
    config.SUPABASE_URL,
    config.SUPABASE_ANON_KEY
  );

  try {
    const { data: profile, error: profileError } = await supabase
      .from("profiles")
      .select("user_id, display_name, share_enabled")
      .eq("share_slug", slug)
      .eq("share_enabled", true)
      .maybeSingle();

    if (profileError) throw profileError;
    if (!profile) {
      content.className = "state";
      content.textContent =
        "공유가 꺼져 있거나 링크를 찾을 수 없어요.";
      document.getElementById("summary").textContent = "";
      return;
    }

    ownerProfile = profile;

    const { data: items, error: itemsError } = await supabase
      .from("items")
      .select(
        "id, title, image_url, price, product_url, mall, category, list_type"
      )
      .eq("user_id", profile.user_id)
      .eq("list_type", "wishlist")
      .order("updated_at", { ascending: false });

    if (itemsError) throw itemsError;

    wishItems = items || [];
    const pledgesOK = await reloadPledges();
    const coordsOK = await reloadCoordinations();
    renderItems(profile.display_name, wishItems);
    openPledgeFromQuery();

    if (!pledgesOK) {
      const summary = document.getElementById("summary");
      summary.innerHTML +=
        '<br><span style="color:#d53f00;font-size:12px">약속 펀딩만 불러오지 못했어요. 위시 목록은 표시됩니다.</span>';
    }
  } catch (error) {
    document.getElementById("summary").textContent = "불러오지 못했어요";
    content.className = "state error";
    content.textContent = error.message || String(error);
  }
}

let bootAttempts = 0;

function boot() {
  bootAttempts += 1;

  if (!window.supabase?.createClient || !window.UNIVERSE_CART_CONFIG) {
    if (bootAttempts > 80) {
      showFatal(
        "페이지를 시작하지 못했어요.\nWi‑Fi 연결을 확인한 뒤 Safari에서 새로고침해 주세요."
      );
      return;
    }
    setTimeout(boot, 100);
    return;
  }

  bindSheetEvents();
  main().catch((error) => {
    showFatal(error?.message || String(error));
  });
}

window.addEventListener("error", (event) => {
  if (event.target && event.target !== window) return;
  showFatal(
    "페이지 오류가 발생했어요.\n" + (event.message || "새로고침 후 다시 시도해 주세요.")
  );
});

window.addEventListener("unhandledrejection", (event) => {
  showFatal(
    event.reason?.message || String(event.reason || "알 수 없는 오류가 발생했어요.")
  );
});

window.UCShareApp = { boot };

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", boot);
} else {
  boot();
}

})();
