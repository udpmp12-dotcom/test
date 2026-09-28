// URL del webhook de n8n. Configurar cuando el workflow esté listo.
const N8N_WEBHOOK_URL = "";

const form = document.getElementById("input-form");
const inputText = document.getElementById("input-text");
const submitBtn = document.getElementById("submit-btn");
const loading = document.getElementById("loading");
const output = document.getElementById("output");
const outputText = document.getElementById("output-text");
const errorBox = document.getElementById("error");

form.addEventListener("submit", async (event) => {
  event.preventDefault();

  const value = inputText.value.trim();
  if (!value) return;

  output.classList.add("hidden");
  errorBox.classList.add("hidden");
  loading.classList.remove("hidden");
  submitBtn.disabled = true;

  try {
    if (!N8N_WEBHOOK_URL) {
      throw new Error("El webhook de n8n todavía no está configurado.");
    }

    const response = await fetch(N8N_WEBHOOK_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ input: value }),
    });

    if (!response.ok) {
      throw new Error(`Error del servidor (${response.status})`);
    }

    const data = await response.json();
    const resultText =
      typeof data === "string" ? data : data.output || data.text || JSON.stringify(data);

    outputText.textContent = resultText;
    output.classList.remove("hidden");
  } catch (err) {
    errorBox.textContent = err.message || "Ocurrió un error al procesar la solicitud.";
    errorBox.classList.remove("hidden");
  } finally {
    loading.classList.add("hidden");
    submitBtn.disabled = false;
  }
});
