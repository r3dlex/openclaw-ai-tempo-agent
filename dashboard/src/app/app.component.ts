import { Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet],
  template: `
    <header class="app-header">
      <div class="header-content">
        <h1>Tempo</h1>
        <span class="subtitle">AI Tool Analytics</span>
      </div>
    </header>
    <main class="app-main">
      <router-outlet />
    </main>
  `,
  styles: [`
    .app-header {
      background: rgba(255, 255, 255, 0.1);
      backdrop-filter: blur(10px);
      padding: 16px 32px;
      border-bottom: 1px solid rgba(255, 255, 255, 0.2);
    }
    .header-content {
      display: flex;
      align-items: baseline;
      gap: 12px;
      max-width: 1400px;
      margin: 0 auto;
    }
    h1 {
      color: white;
      font-size: 24px;
      font-weight: 700;
    }
    .subtitle {
      color: rgba(255, 255, 255, 0.8);
      font-size: 14px;
    }
    .app-main {
      max-width: 1400px;
      margin: 24px auto;
      padding: 0 24px;
    }
  `],
})
export class AppComponent {}
