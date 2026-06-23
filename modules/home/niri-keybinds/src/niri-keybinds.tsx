import {
  List,
  Detail,
  ActionPanel,
  Action,
  Icon,
  Color,
  Clipboard,
  showToast,
  Toast,
} from "@vicinae/api";
import { useEffect, useState } from "react";
import { getNiriKeybinds, type NiriBind } from "./utils/niri";

export default function Command() {
  const [isLoading, setIsLoading] = useState(true);
  const [binds, setBinds] = useState<NiriBind[]>([]);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    try {
      setBinds(getNiriKeybinds());
    } catch (e: any) {
      setError(e?.message ?? "Failed to read niri config");
    } finally {
      setIsLoading(false);
    }
  }, []);

  if (error) {
    return (
      <Detail markdown={`Failed to load niri keybinds\n\n\`\`\`\n${error}\n\`\`\``} />
    );
  }

  return (
    <List
      isLoading={isLoading}
      searchBarPlaceholder="Search keybinds by name, keys, or action..."
    >
      <List.Section title="Niri Keybinds" subtitle={`${binds.length}`}>
        {binds.map((b, idx) => (
          <List.Item
            key={`${b.keys}-${idx}`}
            title={b.title}
            subtitle={b.fromTitle ? undefined : b.action}
            icon={Icon.Keyboard}
            keywords={[b.keys, b.action, b.title]}
            accessories={[{ tag: { value: b.keys, color: Color.Blue } }]}
            actions={
              <ActionPanel>
                <Action
                  title="Copy Key Combo"
                  icon={Icon.Clipboard}
                  onAction={async () => {
                    await Clipboard.copy(b.keys);
                    await showToast({
                      style: Toast.Style.Success,
                      title: "Copied",
                      message: b.keys,
                    });
                  }}
                />
              </ActionPanel>
            }
          />
        ))}
      </List.Section>
    </List>
  );
}
