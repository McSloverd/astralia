document.getElementById('login-form').addEventListener('submit', async function(e) {
  e.preventDefault();
  const username = document.getElementById('username').value.trim();
  const password = document.getElementById('password').value;
  const errorDiv = document.getElementById('login-error');
  errorDiv.textContent = '';
  try {
    const resp = await fetch('/api/admin/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username, password })
    });
    const data = await resp.json();
    if (resp.ok && data.token) {
      sessionStorage.setItem('admin_token', data.token);
      window.location.href = 'index.html';
    } else {
      errorDiv.textContent = data.error || "Login failed.";
    }
  } catch (err) {
    errorDiv.textContent = "Network error.";
  }
});
