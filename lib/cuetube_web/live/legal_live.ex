defmodule CuetubeWeb.LegalLive do
  use CuetubeWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(_params, _url, socket) do
    page =
      case socket.assigns.live_action do
        :privacy -> "privacy"
        :terms -> "terms"
        _ -> "privacy"
      end

    page_title = if page == "privacy", do: "Privacy Policy", else: "Terms of Service"
    {:noreply, assign(socket, page: page, page_title: page_title)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <div class="container legal-content-wrapper">
        <div class="legal-content">
          <%= if @page == "privacy" do %>
            <.privacy_policy />
          <% else %>
            <.terms_of_service />
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def privacy_policy(assigns) do
    ~H"""
    <section>
      <h1>Privacy Policy</h1>
      <p>
        Cuetube is designed to be as minimal as possible regarding your data. We respect your privacy and only collect what is strictly necessary to provide the service.
      </p>

      <h2>1. Data We Collect</h2>
      <p>
        We only collect what is necessary to provide the service:
        <ul>
          <li>
            <strong>Authentication:</strong>
            Basic profile info from your Google account (Email, Name, Avatar) provided via OAuth.
          </li>
          <li>
            <strong>Curation:</strong>
            Playlists, descriptions, and video selections you explicitly create or modify on our platform.
          </li>
        </ul>
      </p>

      <h2>2. How We Use Your Data</h2>
      <p>
        Your data is used solely to provide and maintain your playlists.
        <ul>
          <li>We do NOT sell your data to third parties.</li>
          <li>We do NOT use your data for advertising or profiling.</li>
          <li>We do NOT share your private playlists without your consent.</li>
        </ul>
      </p>

      <h2>3. Third Parties</h2>
      <p>
        Cuetube interacts with the following third-party services:
        <ul>
          <li><strong>Google:</strong> Used for secure authentication.</li>
          <li><strong>YouTube:</strong> Used to fetch video metadata and embed videos.</li>
        </ul>
        By using Cuetube, you are also bound by the Google Privacy Policy and YouTube Terms of Service.
      </p>

      <h2>4. Data Deletion</h2>
      <p>
        You can delete your playlists at any time. If you wish to delete your account and all associated data, please contact us.
      </p>

      <h2>5. Contact</h2>
      <p>
        If you have any questions about this policy, feel free to reach out via our official GitHub repository or contact channels.
      </p>
    </section>
    """
  end

  def terms_of_service(assigns) do
    ~H"""
    <section>
      <h1>Terms of Service</h1>
      <p>By using Cuetube, you agree to these simple and human-readable terms.</p>

      <h2>1. Use of Service</h2>
      <p>
        Cuetube is a tool for augmenting and curating YouTube playlists. You agree to use it responsibly and not for any illegal activities or to disrupt the service for others.
      </p>

      <h2>2. Your Content</h2>
      <p>
        You retain ownership of the curation data (descriptions, orderings) you create. However, the video content itself is hosted by YouTube and subject to their terms.
      </p>

      <h2>3. Disclaimer</h2>
      <p>
        The service is provided "as is" without any warranties of any kind. While we strive for 100% uptime and data integrity, we are not responsible for any data loss or service interruptions.
      </p>

      <h2>4. Prohibited Actions</h2>
      <p>
        You may not use Cuetube to:
        <ul>
          <li>Spam or harass other users.</li>
          <li>Attempt to scrape or reverse engineer the service.</li>
          <li>Distribute malicious software.</li>
        </ul>
      </p>

      <h2>5. Changes to Terms</h2>
      <p>
        We may update these terms occasionally to reflect changes in our service or legal requirements. Continued use of Cuetube constitutes acceptance of the updated terms.
      </p>
    </section>
    """
  end
end
