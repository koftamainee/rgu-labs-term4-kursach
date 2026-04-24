#include <cmath>
#include <map>
#include <print>
#include <string>
#include <vector>
#include "task_runner.hpp"

std::string vigenere_encrypt(const std::string& msg, const std::string& key) {
  std::string out(msg.size(), ' ');
  for (size_t i = 0; i < msg.size(); ++i)
    out[i] = 'a' + (msg[i] - 'a' + key[i % key.size()] - 'a') % 26;
  return out;
}

std::string vernam_encrypt(const std::string& msg, const std::string& key) {
  std::string out(msg.size(), ' ');
  for (size_t i = 0; i < msg.size(); ++i)
    out[i] = 'a' + ((msg[i] - 'a') ^ (key[i % key.size()] - 'a')) % 26;
  return out;
}

void analyze(
    const std::vector<std::string>& msgs,
    const std::vector<double>& msg_probs,
    const std::vector<std::string>& keys,
    const std::vector<double>& key_probs,
    const std::string& target_cipher,
    const std::string& target_msg,
    bool use_vigenere) {
  auto encrypt = [&](const std::string& m, const std::string& k) {
    return use_vigenere ? vigenere_encrypt(m, k) : vernam_encrypt(m, k);
  };

  std::map<std::string, double> p_cipher;
  std::map<std::string, std::map<std::string, double>> p_cipher_given_msg;

  for (size_t j = 0; j < msgs.size(); ++j)
    for (size_t s = 0; s < keys.size(); ++s) {
      std::string c = encrypt(msgs[j], keys[s]);
      p_cipher[c] += msg_probs[j] * key_probs[s];
      p_cipher_given_msg[msgs[j]][c] += key_probs[s];
    }

  double pm = 0.0;
  for (size_t j = 0; j < msgs.size(); ++j)
    if (msgs[j] == target_msg) {
      pm = msg_probs[j];
      break;
    }

  double pc = p_cipher.count(target_cipher)
                ? p_cipher.at(target_cipher)
                : 0.0;
  double pcm = (p_cipher_given_msg.count(target_msg) &&
                p_cipher_given_msg.at(target_msg).count(target_cipher))
                 ? p_cipher_given_msg.at(target_msg).at(target_cipher)
                 : 0.0;
  double pmc = (pc > 0.0) ? (pcm * pm / pc) : 0.0;

  std::println("  P(Cipher='{}')             = {:.4f}", target_cipher, pc);
  std::println("  P(Cipher='{}'|M='{}') = {:.4f}", target_cipher, target_msg,
               pcm);
  std::println("  P(M='{}'|Cipher='{}') = {:.4f}", target_msg, target_cipher,
               pmc);
  std::println("  Perfect secrecy?           = {}",
               std::abs(pmc - pm) < 1e-9 ? "YES" : "NO");
}

int main() {
  std::vector<std::string> msgs = {"ab", "ba", "aa"};
  std::vector<double> msg_probs = {0.5, 0.3, 0.2};

  std::vector<std::string> keys = {"aa", "ab", "ba", "bb"};
  std::vector<double> key_probs_uniform = {0.25, 0.25, 0.25, 0.25};
  std::vector<double> key_probs_nonuniform = {0.5, 0.2, 0.2, 0.1};

  std::println("=== Vigenere (non-uniform keys) ===");
  analyze(msgs, msg_probs, keys, key_probs_nonuniform, "ba", "ab", true);
  std::println("");

  std::println("=== Vigenere (uniform keys) ===");
  analyze(msgs, msg_probs, keys, key_probs_uniform, "ba", "ab", true);
  std::println("");

  std::println("=== Vernam (non-uniform keys) ===");
  analyze(msgs, msg_probs, keys, key_probs_nonuniform, "ba", "ab", false);
  std::println("");

  std::println("=== Vernam (uniform keys) ===");
  analyze(msgs, msg_probs, keys, key_probs_uniform, "ba", "ab", false);

  return 0;
}
