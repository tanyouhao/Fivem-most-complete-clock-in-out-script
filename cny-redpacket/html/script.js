/**
 * CNY Red Packet NUI Script
 *
 * IMPORTANT: This NUI does NOT use SetNuiFocus.
 * It is purely visual (overlay) so it will NEVER block the player's
 * inventory, controls, or mouse. This prevents the common bug where
 * players cannot open inventory after using the item.
 */

let animationTimer = null;

// ============================================================
// LISTEN FOR NUI MESSAGES FROM CLIENT LUA
// ============================================================

window.addEventListener('message', function(event) {
    const data = event.data;

    if (data.action === 'openPacket') {
        showPacket(data);
    }

    if (data.action === 'closePacket') {
        hidePacket();
    }
});

// ============================================================
// SHOW THE RED PACKET
// ============================================================

function showPacket(data) {
    const container = document.getElementById('packet-container');
    const packet = document.getElementById('red-packet');
    const rewardDisplay = document.getElementById('reward-display');
    const rewardAmount = document.getElementById('reward-amount');
    const jackpotText = document.getElementById('jackpot-text');
    const particles = document.getElementById('particles');

    // Reset state
    container.classList.remove('hidden', 'fade-out');
    packet.classList.remove('opening', 'hidden', 'gold');
    rewardDisplay.classList.add('hidden');
    jackpotText.classList.add('hidden');
    particles.innerHTML = '';

    // Apply gold variant if needed
    if (data.animation === 'gold') {
        packet.classList.add('gold');
    }

    // Spawn particles
    spawnParticles(data.isJackpot);

    // After brief delay, start opening animation
    setTimeout(function() {
        packet.classList.add('opening');

        // Show reward after packet opens
        setTimeout(function() {
            packet.classList.add('hidden');
            rewardDisplay.classList.remove('hidden');
            rewardAmount.textContent = '$' + numberWithCommas(data.reward);

            if (data.isJackpot) {
                jackpotText.classList.remove('hidden');
                spawnParticles(true); // Extra particles for jackpot
            }
        }, 1000);
    }, 800);

    // Auto-hide after duration
    const duration = data.duration || 3000;
    if (animationTimer) clearTimeout(animationTimer);
    animationTimer = setTimeout(function() {
        hidePacket();
    }, duration);
}

// ============================================================
// HIDE THE RED PACKET
// ============================================================

function hidePacket() {
    const container = document.getElementById('packet-container');
    container.classList.add('fade-out');

    setTimeout(function() {
        container.classList.add('hidden');
        container.classList.remove('fade-out');
        document.getElementById('particles').innerHTML = '';

        // Notify Lua that packet UI is closed
        fetch('https://cny-redpacket/packetClosed', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        }).catch(function() {});
    }, 500);

    if (animationTimer) {
        clearTimeout(animationTimer);
        animationTimer = null;
    }
}

// ============================================================
// PARTICLES
// ============================================================

function spawnParticles(isJackpot) {
    const container = document.getElementById('particles');
    const count = isJackpot ? 40 : 20;
    const colors = ['#ffd700', '#ff4444', '#ffcc00', '#ff6b6b', '#ffe066', '#ff8888'];

    for (let i = 0; i < count; i++) {
        const particle = document.createElement('div');
        const isCoin = Math.random() > 0.5;

        particle.classList.add('particle');
        particle.classList.add(isCoin ? 'coin' : 'confetti');

        if (!isCoin) {
            particle.style.backgroundColor = colors[Math.floor(Math.random() * colors.length)];
        }

        particle.style.left = Math.random() * 100 + '%';
        particle.style.top = '-20px';
        particle.style.animation = 'particleFall ' + (2 + Math.random() * 3) + 's linear ' + (Math.random() * 1.5) + 's forwards';

        container.appendChild(particle);
    }
}

// ============================================================
// UTILITY
// ============================================================

function numberWithCommas(x) {
    return x.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}
