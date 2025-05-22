let adminToken = sessionStorage.getItem('admin_token');
if (!adminToken) window.location.href = 'login.html';

const usersTableContainer = document.getElementById('users-table-container');
const userActionMsg = document.getElementById('user-action-msg');
const expiryForm = document.getElementById('expiry-form');
const expiryDaysInput = document.getElementById('expiry-days');
const expirySuccess = document.getElementById('expiry-success');

document.getElementById('logout-btn').onclick = () => {
  sessionStorage.removeItem('admin_token');
  window.location.href = 'login.html';
};

async function fetchUsers() {
  usersTableContainer.innerHTML = "Loading...";
  try {
    const resp = await fetch('/api/admin/users', {
      headers: { 'Authorization': 'Bearer ' + adminToken },
    });
    if (!resp.ok) throw new Error('Failed to fetch users');
    const data = await resp.json();
    renderUsersTable(data.users || []);
  } catch (err) {
    usersTableContainer.innerHTML = 'Failed to load users.';
  }
}

function renderUsersTable(users) {
  if (users.length === 0) {
    usersTableContainer.innerHTML = "<p>No users registered.</p>";
    return;
  }
  let html = `<table class="users-table"><thead>
    <tr>
      <th>Username</th>
      <th>Status</th>
      <th>Registered</th>
      <th>Approved</th>
      <th>Expiry</th>
      <th>Last Login IP</th>
      <th>Actions</th>
    </tr></thead><tbody>`;
  for (const u of users) {
    html += `<tr>
      <td>${u.username}</td>
      <td>${u.status}</td>
      <td>${u.registration_date ? new Date(u.registration_date).toLocaleString() : '-'}</td>
      <td>${u.approval_date ? new Date(u.approval_date).toLocaleString() : '-'}</td>
      <td>${u.expiry_date ? new Date(u.expiry_date).toLocaleString() : '-'}</td>
      <td>${u.last_login_ip || '-'}</td>
      <td>
        ${u.status === 'pending' ? `<button onclick="approveUser(${u.id})">Approve</button>` : ''}
        ${u.status === 'approved' ? `<button onclick="deactivateUser(${u.id})">Deactivate</button>` : ''}
        ${(u.status === 'deactivated' || u.status === 'expired') ? `<button onclick="reactivateUser(${u.id})">Reactivate</button>` : ''}
      </td>
    </tr>`;
  }
  html += "</tbody></table>";
  usersTableContainer.innerHTML = html;
}

async function approveUser(id) {
  if (!confirm("Approve this user?")) return;
  userActionMsg.textContent = '';
  try {
    const resp = await fetch(`/api/admin/users/${id}/approve`, {
      method: 'POST',
      headers: { 'Authorization': 'Bearer ' + adminToken }
    });
    if (!resp.ok) throw new Error();
    userActionMsg.textContent = "User approved.";
    fetchUsers();
  } catch {
    userActionMsg.textContent = "Failed to approve user.";
  }
}

async function deactivateUser(id) {
  if (!confirm("Deactivate this user?")) return;
  userActionMsg.textContent = '';
  try {
    const resp = await fetch(`/api/admin/users/${id}/deactivate`, {
      method: 'POST',
      headers: { 'Authorization': 'Bearer ' + adminToken }
    });
    if (!resp.ok) throw new Error();
    userActionMsg.textContent = "User deactivated.";
    fetchUsers();
  } catch {
    userActionMsg.textContent = "Failed to deactivate user.";
  }
}

async function reactivateUser(id) {
  if (!confirm("Reactivate this user?")) return;
  userActionMsg.textContent = '';
  try {
    const resp = await fetch(`/api/admin/users/${id}/reactivate`, {
      method: 'POST',
      headers: { 'Authorization': 'Bearer ' + adminToken }
    });
    if (!resp.ok) throw new Error();
    userActionMsg.textContent = "User reactivated.";
    fetchUsers();
  } catch {
    userActionMsg.textContent = "Failed to reactivate user.";
  }
}

// Fetch expiry days on load and allow update
async function fetchExpiryDays() {
  expirySuccess.textContent = '';
  try {
    const resp = await fetch('/api/admin/users', {
      headers: { 'Authorization': 'Bearer ' + adminToken }
    });
    if (!resp.ok) throw new Error();
    // Just get the expiry from first user as a placeholder
    const data = await resp.json();
    let days = 30;
    if (data.users && data.users.length > 0 && data.users[0].expiry_date && data.users[0].approval_date) {
      const expiry = new Date(data.users[0].expiry_date);
      const approval = new Date(data.users[0].approval_date);
      days = Math.round((expiry - approval) / (1000 * 60 * 60 * 24));
    }
    expiryDaysInput.value = days;
  } catch {}
}

expiryForm.onsubmit = async function(e) {
  e.preventDefault();
  expirySuccess.textContent = '';
  const days = Number(expiryDaysInput.value);
  if (!days || days < 1) {
    expirySuccess.textContent = "Please enter a valid number.";
    return;
  }
  try {
    const resp = await fetch('/api/admin/settings/expiry', {
      method: 'POST',
      headers: {
        'Authorization': 'Bearer ' + adminToken,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ days })
    });
    if (!resp.ok) throw new Error();
    expirySuccess.textContent = "Expiry days updated.";
    fetchUsers();
  } catch {
    expirySuccess.textContent = "Failed to update expiry days.";
  }
};

fetchUsers();
fetchExpiryDays();
