const N8N_WEBHOOK_URL = "https://n8n-fpgz.srv1928618.hstgr.cloud/webhook/alcance-penal-web";

const form = document.getElementById("input-form");
const inputText = document.getElementById("input-text");
const submitBtn = document.getElementById("submit-btn");
const loading = document.getElementById("loading");
const output = document.getElementById("output");
const outputText = document.getElementById("output-text");
const avisoText = document.getElementById("aviso-text");
const errorBox = document.getElementById("error");
const editPrompt = document.getElementById("edit-prompt");
const editYesBtn = document.getElementById("edit-yes-btn");
const editNoBtn = document.getElementById("edit-no-btn");
const editForm = document.getElementById("edit-form");
const editText = document.getElementById("edit-text");
const editSubmitBtn = document.getElementById("edit-submit-btn");
const doneBox = document.getElementById("done");

let currentArticle = "";

function hideAll() {
  output.classList.add("hidden");
  avisoText.classList.add("hidden");
  errorBox.classList.add("hidden");
  editPrompt.classList.add("hidden");
  editForm.classList.add("hidden");
  doneBox.classList.add("hidden");
}

function showArticle(articulo, aviso) {
  outputText.textContent = articulo;
  output.classList.remove("hidden");
  if (aviso) {
    avisoText.textContent = aviso;
    avisoText.classList.remove("hidden");
  }
  editPrompt.classList.remove("hidden");
}

async function callWebhook(payload) {
  const response = await fetch(N8N_WEBHOOK_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });

  const data = await response.json();

  if (!response.ok) {
    throw new Error(data.mensaje || `Error del servidor (${response.status})`);
  }

  return data;
}

form.addEventListener("submit", async (event) => {
  event.preventDefault();

  const value = inputText.value.trim();
  if (!value) return;

  hideAll();
  loading.classList.remove("hidden");
  submitBtn.disabled = true;

  try {
    const data = await callWebhook({ accion: "generar", input: value });
    currentArticle = data.articulo || "";
    showArticle(currentArticle, null);
  } catch (err) {
    errorBox.textContent = err.message || "Ocurrió un error al procesar la solicitud.";
    errorBox.classList.remove("hidden");
  } finally {
    loading.classList.add("hidden");
    submitBtn.disabled = false;
  }
});

editYesBtn.addEventListener("click", () => {
  editPrompt.classList.add("hidden");
  editForm.classList.remove("hidden");
  editText.value = "";
  editText.focus();
});

editNoBtn.addEventListener("click", () => {
  editPrompt.classList.add("hidden");
  doneBox.classList.remove("hidden");
});

editForm.addEventListener("submit", async (event) => {
  event.preventDefault();

  const instruccion = editText.value.trim();
  if (!instruccion) return;

  avisoText.classList.add("hidden");
  errorBox.classList.add("hidden");
  editForm.classList.add("hidden");
  loading.classList.remove("hidden");
  editSubmitBtn.disabled = true;

  try {
    const data = await callWebhook({
      accion: "editar",
      articulo: currentArticle,
      instruccion,
    });
    currentArticle = data.articulo || currentArticle;
    showArticle(currentArticle, data.aviso);
  } catch (err) {
    errorBox.textContent = err.message || "Ocurrió un error al procesar la solicitud.";
    errorBox.classList.remove("hidden");
    editPrompt.classList.remove("hidden");
  } finally {
    loading.classList.add("hidden");
    editSubmitBtn.disabled = false;
  }
});
